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

    expect(campaign.statusLabel, 'تجربة جافة جاهزة');
    expect(campaign.recipientCount, 12);
    expect(campaign.externalSend, isFalse);
    expect(preview.items.single.typeLabel, 'مستخدمي الكروت');
  });

  test('generated keys hide technical input from UI while remaining safe', () {
    final key = generatedKey('تنبيه صيانة', 'template');
    expect(key.startsWith('template_'), isTrue);
    expect(key.contains(' '), isFalse);
  });
}
