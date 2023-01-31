import 'package:be_safe/live_safe/hotels_card.dart';
import 'package:be_safe/live_safe/pharmacy_card.dart';
import 'package:be_safe/live_safe/police_station_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher.dart';

import 'bus_station_card.dart';
import 'hospital_card.dart';

class LiveSafe extends StatefulWidget {
  const LiveSafe({super.key});

  @override
  State<LiveSafe> createState() => _LiveSafeState();
}

class _LiveSafeState extends State<LiveSafe> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      width: MediaQuery.of(context).size.width,
      child: ListView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          children: const [
            PoliceStationCard(onMapFunction: openMap),
            Hospital(onMapFunction: openMap),
            BusStationCard(onMapFunction: openMap),
            PharmacyCard(onMapFunction: openMap),
            HotelsCard(onMapFunction: openMap)
          ]),
    );
  }

  static Future<void> openMap(String location) async {
    String googleUrl = 'https://www.google.com/maps/search/$location';
    final Uri url = Uri.parse(googleUrl);

    try {
      await launchUrl(url);
    } catch (e) {
      Fluttertoast.showToast(
          msg: "Something went wrong! Call emergency numbers.");
    }
  }
}
