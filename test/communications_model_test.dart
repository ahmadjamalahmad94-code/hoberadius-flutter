import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/communications/domain/communications_model.dart';

void main() {
  test('communications home parses dashboard payload', () {
    final home = CommunicationsHome.fromJson({
      'data': {
        'summary': {
          'templates': 2,
          'segments': 1,
          'queued': 3,
          'sent': 0,
          'failed': 1,
        },
        'templates': [
          {
            'id': 9,
            'template_key': 'renewal',
            'title': 'تذكير تجديد',
            'channel': 'internal',
            'subject': 'تذكير',
            'body': 'أهلًا',
            'status': 'active',
          },
        ],
        'segments': [
          {
            'id': 5,
            'segment_key': 'company',
            'title': 'الشركة',
            'status': 'active',
            'filters': {'target': 'company'},
          },
        ],
        'deliveries': [
          {
            'id': 7,
            'channel': 'sms',
            'status': 'queued',
            'recipient_type': 'subscriber',
            'recipient_id': 44,
            'subject': 'تنبيه',
            'body': 'نص',
            'created_at': '2026-05-31T12:30:00Z',
          },
        ],
      },
    });

    expect(home.summary.templates, 2);
    expect(home.templates.single.channelLabel, 'رسالة داخلية');
    expect(home.segments.single.targetLabel, 'الشركة');
    expect(home.deliveries.single.channelLabel, 'رسالة جوال');
    expect(home.deliveries.single.statusLabel, 'في الطابور');
    expect(home.deliveries.single.recipientLabel, 'المشتركين #44');
    expect(home.deliveries.single.createdAtLabel, '2026-05-31 12:30');
  });

  test('campaign and audience labels are Arabic friendly', () {
    final campaign = MessageCampaign.fromJson({
      'id': 1,
      'campaign_key': 'maintenance',
      'title': 'صيانة',
      'channel': 'internal',
      'status': 'dry_run_ready',
      'template_id': 9,
      'dry_run': {'recipient_count': 12, 'external_send': false},
    });
    final preview = AudiencePreview.fromJson({
      'data': {
        'count': 1,
        'items': [
          {
            'recipient_type': 'card_user',
            'recipient_id': 3,
            'display_name': 'مستخدم كرت',
            'address': '0590000000',
          },
        ],
      },
    });

    expect(campaign.statusLabel, 'معاينة جاهزة');
    expect(campaign.recipientCount, 12);
    expect(campaign.externalSend, isFalse);
    expect(preview.items.single.typeLabel, 'مستخدمي الكروت');
  });

  test('channel settings and quota payloads parse provider contract', () {
    final channels = CommunicationChannelPage.fromJson({
      'data': {
        'count': 2,
        'methods': ['GET', 'POST'],
        'modes': [
          {'key': 'self_api', 'label': 'ربط مباشر من العميل'},
          {'key': 'admin_quota', 'label': 'رصيد مخصص من الإدارة'},
        ],
        'items': [
          {
            'channel': 'sms',
            'label': 'الرسائل القصيرة',
            'enabled': true,
            'active': true,
            'mode': 'admin_quota',
            'mode_label': 'رصيد مخصص من الإدارة',
            'config': {
              'send_url_template':
                  'https://provider.example/send?to={phone}&text={msg}',
              'http_method': 'POST',
              'balance_url': 'https://provider.example/balance',
            },
            'quota': {
              'balance': 150,
              'used': 12,
              'is_quota_mode': true,
            },
          },
        ],
      },
    });
    final quota = CommunicationQuotaPage.fromJson({
      'data': {
        'count': 1,
        'items': [
          {
            'channel': 'sms',
            'label': 'الرسائل القصيرة',
            'mode': 'admin_quota',
            'mode_label': 'رصيد مخصص من الإدارة',
            'balance': 150,
            'used': 12,
            'is_quota_mode': true,
            'ledger': [
              {
                'ts': '2026-06-05T10:15:00Z',
                'delta': 100,
                'by': 'admin:1',
                'note': 'دفعة شهرية',
                'balance_after': 150,
              },
            ],
          },
        ],
      },
    });

    expect(channels.count, 2);
    expect(channels.items.single.channel, 'sms');
    expect(channels.items.single.statusLabel, 'جاهزة للإرسال');
    expect(channels.items.single.config.httpMethod, 'POST');
    expect(channels.items.single.quota.balance, 150);
    expect(channels.modes.last.label, 'رصيد مخصص من الإدارة');
    expect(quota.items.single.ledger.single.note, 'دفعة شهرية');
    expect(quota.items.single.ledger.single.tsLabel, '2026-06-05 10:15');
  });

  test('quota credit result parses Arabic success message', () {
    final result = CommunicationQuotaCreditResult.fromJson({
      'data': {
        'balance_after': 250,
        'message': 'تمت إضافة 100 رسالة إلى رصيد الرسائل القصيرة.',
        'quota': {
          'channel': 'sms',
          'label': 'الرسائل القصيرة',
          'mode': 'admin_quota',
          'mode_label': 'رصيد مخصص من الإدارة',
          'balance': 250,
          'used': 12,
          'is_quota_mode': true,
          'ledger': [],
        },
      },
    });

    expect(result.balanceAfter, 250);
    expect(result.message, contains('تمت إضافة'));
    expect(result.quota.isQuotaMode, isTrue);
  });

  test('generated keys hide technical input from UI while remaining safe', () {
    final key = generatedKey('تنبيه صيانة', 'template');
    expect(key.startsWith('template_'), isTrue);
    expect(key.contains(' '), isFalse);
  });
}
