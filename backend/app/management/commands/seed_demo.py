from django.contrib.auth import get_user_model
from django.core.management import call_command
from django.core.management.base import BaseCommand, CommandError
from django.core.management.utils import get_random_secret_key
from django.db import transaction

from app.models import Room
from oidc_provider.models import Client, ResponseType, RSAKey


DEMO_USERNAME = 'student01'
CLIENT_ID = 'flutter-web-app'


class Command(BaseCommand):
    help = 'Create the local course demo account, sample rooms, and OIDC client.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--reset-demo-password',
            action='store_true',
            help='Generate a new random password for student01 and print it once.',
        )

    @transaction.atomic
    def handle(self, *args, **options):
        user_model = get_user_model()
        user, user_created = user_model.objects.get_or_create(
            username=DEMO_USERNAME,
            defaults={
                'is_active': True,
                'is_staff': False,
                'is_superuser': False,
            },
        )
        if user_created or options['reset_demo_password']:
            demo_password = get_random_secret_key()
            user.set_password(demo_password)
            user.is_active = True
            user.is_staff = False
            user.is_superuser = False
            user.save()
            self.stdout.write(self.style.WARNING(
                f'Demo password for {DEMO_USERNAME} (save it now): {demo_password}'
            ))

        sample_rooms = [
            {
                'name': 'ห้องประชุม 1',
                'location': 'อาคารเรียนรวม ชั้น 2',
                'capacity': 20,
                'description': 'ห้องประชุมสำหรับกิจกรรมและการเรียนการสอน',
            },
            {
                'name': 'ห้องปฏิบัติการคอมพิวเตอร์',
                'location': 'คณะวิทยาศาสตร์ ชั้น 3',
                'capacity': 40,
                'description': 'ห้องคอมพิวเตอร์สำหรับการเรียนและทำงานกลุ่ม',
            },
            {
                'name': 'สนามแบดมินตัน',
                'location': 'ศูนย์กีฬา',
                'capacity': 4,
                'description': 'สนามสำหรับจองเล่นกีฬา',
            },
        ]
        for room_data in sample_rooms:
            Room.objects.get_or_create(name=room_data['name'], defaults=room_data)

        code_response_type, _ = ResponseType.objects.get_or_create(
            value='code',
            defaults={'description': 'Authorization Code Flow'},
        )
        client, _ = Client.objects.get_or_create(
            client_id=CLIENT_ID,
            defaults={'name': 'Flutter Web App'},
        )
        client.name = 'Flutter Web App'
        client.client_type = 'public'
        client.client_secret = ''
        client.redirect_uris = ['http://localhost:50000/callback']
        client.post_logout_redirect_uris = ['http://localhost:50000/login']
        client.scope = ['openid', 'profile', 'email']
        client.reuse_consent = True
        client.require_consent = True
        client.save()
        client.response_types.set([code_response_type])

        if not RSAKey.objects.exists():
            call_command('creatersakey', stdout=self.stdout)
            if not RSAKey.objects.exists():
                raise CommandError('Could not generate the OIDC signing key.')

        if not user_created and not options['reset_demo_password']:
            self.stdout.write(
                f'Demo user {DEMO_USERNAME} already exists; password left unchanged.'
            )
        self.stdout.write(self.style.SUCCESS(
            'Demo rooms, public OIDC client, and signing key are ready.'
        ))
