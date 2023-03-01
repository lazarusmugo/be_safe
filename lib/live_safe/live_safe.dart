import 'package:be_safe/live_safe/hotels_card.dart';
import 'package:be_safe/live_safe/pharmacy_card.dart';
import 'package:be_safe/live_safe/police_station_card.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

import 'package:url_launcher/url_launcher.dart';
import '../views/maps_view.dart';
import 'bus_station_card.dart';
import 'hospital_card.dart';

class LiveSafe extends StatefulWidget {
  @override
  State<LiveSafe> createState() => _LiveSafeState();
}

class _LiveSafeState extends State<LiveSafe> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BE SAFE'),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
              height: 100,
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                children: const [
                  PoliceStationCard(onMapFunction: openMap),
                  Hospital(onMapFunction: openMap),
                  BusStationCard(onMapFunction: openMap),
                  PharmacyCard(onMapFunction: openMap),
                  HotelsCard(onMapFunction: openMap)
                ],
              ),
            ),
          ),
          Expanded(
              child: MapsView(
            key: UniqueKey(),
          )),
        ],
      ),
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
