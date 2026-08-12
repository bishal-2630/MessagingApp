from rest_framework.decorators import permission_classes
import os
import requests
from rest_framework.decorators import authentication_classes
from .models import User, EmailVerificationOTP, PasswordResetOTP
from chat.models import FCMDeviceToken
from functools import partial
from users.serializers import ProfileSerializer
from rest_framework import status, viewsets
from django.shortcuts import render
from django.http import JsonResponse
from rest_framework.views import APIView
from .serializers import UserSerializer
from rest_framework.response import Response
from django.contrib.auth import authenticate
from django.utils import timezone
from rest_framework.permissions import AllowAny
from rest_framework.authtoken.models import Token
from rest_framework_simplejwt.tokens import RefreshToken



def send_email_otp(email, otp_code, subject, title_text):
    email_sent = False
    email_errors = []

    # 1. Try Resend API (HTTPS port 443 - Works on Hugging Face)
    resend_api_key = os.getenv('RESEND_API_KEY')
    if resend_api_key:
        try:
            resp = requests.post(
                'https://api.resend.com/emails',
                headers={
                    'Authorization': f'Bearer {resend_api_key}',
                    'Content-Type': 'application/json',
                },
                json={
                    'from': 'ChatMe <onboarding@resend.dev>',
                    'to': [email],
                    'subject': subject,
                    'html': f'<p>{title_text}: <strong style="font-size: 24px; color: #34B7F1;">{otp_code}</strong></p><p>This code expires in 10 minutes.</p>',
                },
                timeout=10,
            )
            print(f"[DEBUG] Resend status={resp.status_code} body={resp.text}")
            if resp.status_code in [200, 201]:
                email_sent = True
            else:
                email_errors.append(f"Resend HTTP {resp.status_code}: {resp.text}")
        except Exception as r_err:
            email_errors.append(f"Resend exception: {r_err}")

    # 2. Try Gmail Webhook URL (HTTPS port 443)
    if not email_sent:
        gmail_webhook_url = os.getenv('GMAIL_WEBHOOK_URL')
        if gmail_webhook_url:
            try:
                resp = requests.post(
                    gmail_webhook_url,
                    json={
                        'to': email,
                        'subject': subject,
                        'html': f'<p>{title_text}: <strong style="font-size: 24px; color: #34B7F1;">{otp_code}</strong></p><p>This code expires in 10 minutes.</p>',
                    },
                    timeout=15,
                )
                print(f"[DEBUG] Webhook status={resp.status_code} body={resp.text}")
                if resp.status_code == 200 and 'error' not in resp.text.lower():
                    email_sent = True
                else:
                    email_errors.append(f"Gmail Webhook HTTP {resp.status_code}: {resp.text}")
            except Exception as w_err:
                email_errors.append(f"Gmail Webhook exception: {w_err}")

    # 3. Try Django SMTP send_mail (Port 587 - local)
    if not email_sent:
        try:
            from django.core.mail import send_mail
            from django.conf import settings
            send_mail(
                subject=subject,
                message=f'{title_text}: {otp_code}\n\nThis code expires in 10 minutes.\nDo not share this code with anyone.',
                from_email=settings.EMAIL_HOST_USER,
                recipient_list=[email],
                fail_silently=False,
            )
            email_sent = True
        except Exception as smtp_err:
            email_errors.append(f"SMTP error: {smtp_err}")

    print(f"[OTP LOG] OTP for {email} is: {otp_code} (email_sent={email_sent})")
    return email_sent, email_errors


class RegisterView(APIView):
    permission_classes = []
    def post(self, request):
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            user.is_email_verified = False
            user.save()

            otp_code = str(random.randint(100000, 999999))
            EmailVerificationOTP.objects.create(user=user, otp=otp_code)

            send_email_otp(
                email=user.email,
                otp_code=otp_code,
                subject='Verify your ChatMe account',
                title_text='Your verification code is'
            )
            return Response(
                {'message': 'Account created. Please verify your email.', 'email': user.email},
                status=status.HTTP_201_CREATED
            )
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class LoginView(APIView):
    permission_classes = []
    def post(self, request):
        email = request.data.get('email')
        password = request.data.get('password')
        user = authenticate(request, username=email, password=password)
        if user:
            if not user.is_email_verified:
                return Response({'error': 'Email not verified. Please verify your email first.', 'code': 'email_not_verified', 'email': user.email}, status=status.HTTP_403_FORBIDDEN)

            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user_id': user.id,
                'username': user.username,
            })
        return Response({'error': 'Invalid credentials'}, status=status.HTTP_401_UNAUTHORIZED)

class ProfileView(APIView):
    def get(self, request):
        user = request.user
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    def put(self, request):
        profile = request.user.profile  
        serializer = ProfileSerializer(profile, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class DeleteAccountView(APIView):
    def delete(self, request):
        user = request.user
        user.delete()
        return Response({'message': 'Account deleted successfully.'}, status=status.HTTP_200_OK)

class UserViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = User.objects.all()
    serializer_class = UserSerializer

class UserSearchView(APIView):
    def get(self,request):
        username= request.query_params.get('username')
        if not username:
            return Response({'No Match Found '}, status= status.HTTP_400_BAD_REQUEST)

        user = User.objects.filter(username__iexact=username).exclude(id=request.user.id).first()

        if not user:
            return Response({'No User Found.'}, status=status.HTTP_404_NOT_FOUND)
        
        serializer = UserSerializer(user)
        return Response(serializer.data)
        

class RegisterFCMTokenView(APIView):
    def post(self, request):
        token = request.data.get('token')
        if not token:
            return Response({'Error': 'Token is required.'},status=status.HTTP_400_BAD_REQUEST)

        obj, created = FCMDeviceToken.objects.update_or_create(
            token=token,
            defaults={'user': request.user}
            )
        return Response({'Success': 'Token registered successfully.'},status=status.HTTP_200_OK)


class UserStatusView(APIView):
    def get(self, request, user_id):
        try:
            from .models import Profile
            profile, _ = Profile.objects.get_or_create(user_id=user_id)
            if profile.is_online:
                return Response({'is_online': True, 'last_seen': ''})
            diff = timezone.now() - profile.last_active
            minutes = int(diff.total_seconds() / 60)
            if minutes < 1:
                last_seen = 'Last seen just now'
            elif minutes < 60:
                last_seen = f'Last seen {minutes}m ago'
            elif minutes < 1440:
                hours = int(minutes / 60)
                last_seen = f'Last seen {hours}h ago'
            else:
                days = minutes // 1440
                last_seen = f'Last seen {days}d ago'
            return Response({'is_online': False, 'last_seen': last_seen})
        except Exception:
            return Response({'is_online': False, 'last_seen': ''})


import random
import secrets
from django.core.mail import send_mail
from django.conf import settings
from .models import PasswordResetOTP

class ForgotPasswordView(APIView):
    permission_classes = []
    authentication_classes = []

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            
            return Response({'error': 'No account found with this email.'}, status=status.HTTP_400_BAD_REQUEST)

        
        PasswordResetOTP.objects.filter(user=user, is_used=False).delete()

        try:
            otp_code = str(random.randint(100000, 999999))
            PasswordResetOTP.objects.create(user=user, otp=otp_code)
            print(f"[DEBUG] OTP created successfully for {email}")
        except Exception as db_err:
            print(f"[DEBUG] DB error creating OTP: {db_err}")
            return Response({'error': f'DB error: {db_err}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        email_sent = False
        email_errors = []

        # 1. Try Google Apps Script / Gmail HTTPS Endpoint (Port 443 - Works on Hugging Face)
        gmail_webhook_url = os.getenv('GMAIL_WEBHOOK_URL')
        if gmail_webhook_url:
            try:
                resp = requests.post(
                    gmail_webhook_url,
                    json={
                        'to': email,
                        'subject': 'Your Password Reset OTP - ChatMe',
                        'html': f'<p>Your OTP code is: <strong style="font-size: 24px; color: #34B7F1;">{otp_code}</strong></p><p>This code expires in 5 minutes.</p>',
                    },
                    timeout=15,
                )
                print(f"[DEBUG] Gmail Webhook status={resp.status_code} body={resp.text}")
                if resp.status_code == 200 and 'error' not in resp.text.lower():
                    email_sent = True
                else:
                    email_errors.append(f"Gmail Webhook HTTP {resp.status_code}: {resp.text}")
            except Exception as w_err:
                print(f"[WARNING] Gmail Webhook exception: {w_err}")
                email_errors.append(f"Gmail Webhook exception: {str(w_err)}")

        # 2. Try Django SMTP send_mail (Port 587 - Works on local machine)
        if not email_sent:
            try:
                send_mail(
                    subject='Your Password Reset OTP - ChatMe',
                    message=f'Your OTP code is: {otp_code}\n\nThis code expires in 5 minutes.\nDo not share this code with anyone.',
                    from_email=settings.EMAIL_HOST_USER,
                    recipient_list=[email],
                    fail_silently=False,
                )
                email_sent = True
            except Exception as smtp_err:
                print(f"[ERROR] send_mail exception: {smtp_err}")
                email_errors.append(f"SMTP error: {str(smtp_err)}")

        # 3. If email delivery failed, print OTP to logs for testing & return detailed error
        if not email_sent:
            print(f"[IMPORTANT] Email not sent. Generated OTP for {email} is: {otp_code}")
            err_details = " | ".join(email_errors)
            return Response(
                {
                    'error': f'Could not send email via HTTPS Webhook or SMTP. Details: {err_details}'
                },
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response({'message': 'OTP has been sent to your email.'})


class VerifyOTPView(APIView):
    permission_classes = []

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp_code = request.data.get('otp', '').strip()

        if not email or not otp_code:
            return Response({'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj = PasswordResetOTP.objects.filter(
            user=user, otp=otp_code, is_used=False
        ).order_by('-created_at').first()

        if not otp_obj:
            return Response({'error': 'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)

        if otp_obj.is_expired():
            return Response({'error': 'OTP has expired. Please request a new one.'}, status=status.HTTP_400_BAD_REQUEST)

        
        reset_token = secrets.token_hex(32)
        otp_obj.reset_token = reset_token
        otp_obj.save()

        return Response({'reset_token': reset_token})


class ResetPasswordView(APIView):
    permission_classes = []

    def post(self, request):
        reset_token = request.data.get('reset_token', '').strip()
        new_password = request.data.get('new_password', '').strip()

        if not reset_token or not new_password:
            return Response({'error': 'Reset token and new password are required.'}, status=status.HTTP_400_BAD_REQUEST)

        if len(new_password) < 8:
            return Response({'error': 'Password must be at least 8 characters.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj = PasswordResetOTP.objects.filter(
            reset_token=reset_token, is_used=False
        ).first()

        if not otp_obj:
            return Response({'error': 'Invalid or expired reset link.'}, status=status.HTTP_400_BAD_REQUEST)

        if otp_obj.is_expired():
            return Response({'error': 'Reset link has expired. Please start over.'}, status=status.HTTP_400_BAD_REQUEST)

        
        user = otp_obj.user
        user.set_password(new_password)
        user.save()

        otp_obj.is_used = True
        otp_obj.save()

        return Response({'message': 'Password reset successfully. You can now log in.'})


class VerifyEmailView(APIView):
    permission_classes = []

    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        otp_code = request.data.get('otp', '').strip()
        if not email or not otp_code:
            return Response({'error': 'Email and OTP are required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error':'Invalid OTP.'}, status=status.HTTP_400_BAD_REQUEST)

        otp_obj = EmailVerificationOTP.objects.filter(
            user = user,
            otp = otp_code,
            is_used = False,
        ).order_by('-created_at').first()

        if not otp_obj or otp_obj.is_expired():
            return Response({'error': 'Invalid or expired OTP.'}, status=status.HTTP_400_BAD_REQUEST)
        
        user.is_email_verified = True
        user.save()

        otp_obj.is_used = True
        otp_obj.save()

        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Email verified successfully.',
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user_id': user.id,
            'username': user.username,
        })

class ResendVerificationView(APIView):
    permission_classes = []
    def post(self, request):
        email = request.data.get('email', '').strip().lower()
        if not email:
            return Response({'error': 'Email is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({'error': 'Account not found.'}, status=status.HTTP_400_BAD_REQUEST)
        if user.is_email_verified:
            return Response({'message': 'Email is already verified.'}, status=status.HTTP_200_OK)
        # Delete unused previous verification OTPs
        EmailVerificationOTP.objects.filter(user=user, is_used=False).delete()
        otp_code = str(random.randint(100000, 999999))
        EmailVerificationOTP.objects.create(user=user, otp=otp_code)
        send_email_otp(
            email=user.email,
            otp_code=otp_code,
            subject='Verify your ChatMe account',
            title_text='Your verification code is'
        )
        return Response({'message': 'A new verification code has been sent to your email.'})

class GoogleLoginView(APIView):
    permission_classes = []
    def post(self, request):
        id_token_str = request.data.get('id_token')
        if not id_token_str:
            return Response({'error': 'ID token is required.'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            resp = requests.get(f"https://www.googleapis.com/oauth2/v3/tokeninfo?id_token={id_token_str}",
            timeout = 10
            )
            if resp.status_code !=200:
                return Response({'error': 'Invalid Google ID token.'}, status=status.HTTP_400_BAD_REQUEST)
            token_data = resp.json()
            email = token_data.get('email', '').strip().lower()
            name = token_data.get('name') or email.split('@')[0]
            
            if not email:
                return Response({'error':'Email not provided by google.'}, status=status.HTTP_400_BAD_REQUEST)
            user, created = User.objects.get_or_create(
                email=email,
                defaults={
                    'username': name,
                    'is_email_verified': True,
                }
            )

            if created:
                user.set_unusable_password()
                user.save()
            elif not user.is_email_verified:
                user.is_email_verified = True
                user.save()
            refresh = RefreshToken.for_user(user)
            return Response({
                'refresh': str(refresh),
                'access': str(refresh.access_token),
                'user_id': user.id,
                'username': user.username,
            })
        except Exception as e:
            return Response({'error': f'Google authentication failed: {str(e)}'}, status=status.HTTP_400_BAD_REQUEST)
            
            