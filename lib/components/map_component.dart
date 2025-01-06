import 'package:flutter/material.dart';
import 'package:qwip_app/data_classes/pod.dart';
import 'package:qwip_app/components/price_marker.dart';
import 'package:syncfusion_flutter_maps/maps.dart';

class MapComponent extends StatefulWidget {
  final List<Pod> pods;
  final Function onMarkerTapped;
  final MapLatLng initialLocation;
  final double initialZoomLevel;

  const MapComponent({
    Key? key,
    required this.pods,
    required this.onMarkerTapped,
    this.initialLocation = const MapLatLng(51.5074, -0.1278), // Default: London
    this.initialZoomLevel = 12.0, // Default zoom level
  }) : super(key: key);

  @override
  _MapComponentState createState() => _MapComponentState();
}

class _MapComponentState extends State<MapComponent> {
  late MapTileLayerController _mapController;
  late MapZoomPanBehavior _zoomPanBehavior;

  @override
  void initState() {
    super.initState();
    // Initialize map controller and zoom/pan behavior
    _mapController = MapTileLayerController();
    _zoomPanBehavior = MapZoomPanBehavior(
      zoomLevel: 12.0,
      enablePanning: true,
      enablePinching: true,
      minZoomLevel: 5,
      maxZoomLevel: 18,
    );
  }

  @override
  void didUpdateWidget(MapComponent oldWidget) {
    print("didUpdateWidget was called!");
    super.didUpdateWidget(oldWidget);

    print('Old pods reference: ${oldWidget.pods.hashCode}');
    print('New pods reference: ${widget.pods.hashCode}');
    // Check if the pods list has changed
    if (oldWidget.pods != widget.pods) {
      print('Refreshing markers!');
      _refreshMarkers();
    } else {
      print('Pods reference has not changed.');
    }
  }

  void _refreshMarkers() {
    setState(() {
      // Trigger a rebuild to update markers
    });
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Map Area
        SfMaps(
          layers: [
            MapTileLayer(
              initialFocalLatLng: widget.initialLocation,
              initialZoomLevel: 12,
              controller: _mapController,
              zoomPanBehavior: _zoomPanBehavior,
              markerBuilder: (context, index) {
                final pod = widget.pods[index];
                return MapMarker(
                  latitude: pod.latitude,
                  longitude: pod.longitude,
                  child: GestureDetector(
                    onTap: () => widget.onMarkerTapped.call(pod),
                    child: PriceMarker(
                        price: pod.price), // Pass price to the rectangle
                  ),
                );
              },
              initialMarkersCount: widget.pods.length,
              urlTemplate:
                  'https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/{z}/{x}/{y}@2x?access_token=sk.eyJ1Ijoic2F4b25zaHJleWFzIiwiYSI6ImNtNTN3YXJkbDEyajQybXNlcTEwZXN0dGMifQ.wsMmb65SO0Hp_V91bIdU0w',
            ),
          ],
        ),
        // Zoom Controls
        Positioned(
          bottom: 16,
          left: 16,
          child: Column(
            children: [
              // Zoom In Button
              FloatingActionButton(
                heroTag: 'zoomIn',
                mini: true,
                onPressed: () {
                  setState(() {
                    _zoomPanBehavior.zoomLevel += 1;
                  });
                },
                backgroundColor: const Color(0xFFF9F8F5), // Cream
                child: const Icon(Icons.add, color: Colors.black),
              ),
              const SizedBox(height: 8),
              // Zoom Out Button
              FloatingActionButton(
                heroTag: 'zoomOut',
                mini: true,
                onPressed: () {
                  setState(() {
                    _zoomPanBehavior.zoomLevel -= 1;
                  });
                },
                backgroundColor: const Color(0xFFF9F8F5), // Cream
                child: const Icon(Icons.remove, color: Colors.black),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
