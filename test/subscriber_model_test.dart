import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hoberadius_app/features/subscribers/application/subscriber_form_mapper.dart';
import 'package:hoberadius_app/features/subscribers/domain/subscriber_model.dart';

void main() {
  test('subscriber model parses and sends custom price', () {
    final subscriber = Subscriber.fromJson({
      'id': 7,
      'username': 'custom-price-user',
      'plan_id': 3,
      'custom_price': '120.50',
      'status': 'enabled',
    });

    expect(subscriber.customPrice, 120.5);

    final body = subscriber.toPatchBody();
    expect(body['custom_price'], 120.5);
  });

  test('subscriber form maps empty custom price to plan price fallback', () {
    final controllers = {
      for (final key in [
        'username',
        'password',
        'full_name',
        'mobile',
        'email',
        'beneficiary_ref',
        'remark',
        'mac_lock',
        'static_ip',
        'plan_id',
        'custom_price',
        'mt_profile',
        'mt_rate_limit',
        'mt_ip_pool',
        'mt_comment',
        'dns1',
        'dns2',
        'simultaneous_use',
        'session_timeout',
        'idle_timeout',
        'called_station_id',
        'allowed_hours',
        'notify_email',
        'notify_mobile',
        'subscription_days',
        'notes',
        'tags',
      ])
        key: TextEditingController(),
    };
    addTearDown(() {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    });

    controllers['username']!.text = 'fallback-user';
    controllers['plan_id']!.text = '2';
    controllers['custom_price']!.text = '';

    final subscriber = buildSubscriberFromForm(
      controllers,
      const SubscriberFormSelections(
        status: 'enabled',
        userType: 'subscriber',
        mtService: 'pppoe',
        subscriptionType: 'fixed',
        expireAt: null,
        workingDays: {},
        disableOnFirstUse: false,
        notifyOnLogin: false,
        autoRenew: true,
      ),
    );

    expect(subscriber.customPrice, 0);
    expect(subscriber.toCreateBody()['custom_price'], 0);
  });
}
