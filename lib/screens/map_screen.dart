import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:in_app_review/in_app_review.dart';

import '../models/alarm.dart';

class MapScreen extends StatefulWidget {
  final void Function(List<Alarm>) onAlarmsAdded;

  const MapScreen({super.key, required this.onAlarmsAdded});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const double _defaultZoom = 14.0;

  GoogleMapController? _mapController;
  final Set<Marker> _markers = {};

  // Each marker ID maps to an Alarm so we can remove them individually
  final Map<MarkerId, Alarm> _markerAlarms = {};

  // Search state
  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  bool _isSearching = false;
  List<Location> _searchLocations = [];
  List<Placemark> _searchPlacemarks = [];
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _moveToCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Location helpers ───────────────────────────────────────────────────────

  Future<void> _moveToCurrentLocation() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(position.latitude, position.longitude),
          _defaultZoom,
        ),
      );
    } catch (_) {}
  }

  // ── Long-press handler ─────────────────────────────────────────────────────

  Future<void> _onLongPress(LatLng latLng) async {
    Placemark? placemark;
    try {
      final results = await placemarkFromCoordinates(latLng.latitude, latLng.longitude);
      if (results.isNotEmpty) placemark = results.first;
    } catch (_) {}
    _addMarker(latLng, placemark);
  }

  void _addMarker(LatLng latLng, Placemark? placemark) {
    final title = placemark?.locality?.isNotEmpty == true
        ? placemark!.locality!
        : placemark?.name?.isNotEmpty == true
            ? placemark!.name!
            : 'Selected Location';

    final subtitle = [
      placemark?.thoroughfare,
      placemark?.subLocality,
      placemark?.postalCode,
      placemark?.country,
    ].where((s) => s != null && s.isNotEmpty).join(', ');

    final markerId = MarkerId('${latLng.latitude},${latLng.longitude}');
    final alarm = Alarm(
      title: title,
      subtitle: subtitle,
      latitude: latLng.latitude,
      longitude: latLng.longitude,
    );

    setState(() {
      _markerAlarms[markerId] = alarm;
      _markers.add(
        Marker(
          markerId: markerId,
          position: latLng,
          infoWindow: InfoWindow(
            title: title,
            snippet: subtitle.isEmpty ? 'Tap to remove' : '$subtitle\n(Tap to remove)',
          ),
          onTap: () => _removeMarker(markerId),
        ),
      );
    });

    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
  }

  void _removeMarker(MarkerId markerId) {
    setState(() {
      _markers.removeWhere((m) => m.markerId == markerId);
      _markerAlarms.remove(markerId);
    });
  }

  // ── Search ─────────────────────────────────────────────────────────────────

  void _onSearchChanged(String query) {
    _searchDebounce?.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchLocations = [];
        _searchPlacemarks = [];
      });
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 500), () => _runSearch(query));
  }

  Future<void> _runSearch(String query) async {
    setState(() => _isSearching = true);
    try {
      final locations = (await locationFromAddress(query)).take(5).toList();
      final placemarks = <Placemark>[];
      for (final loc in locations) {
        final pm = await placemarkFromCoordinates(loc.latitude, loc.longitude);
        placemarks.add(pm.isNotEmpty ? pm.first : const Placemark());
      }
      if (!mounted) return;
      setState(() {
        _searchLocations = locations;
        _searchPlacemarks = placemarks;
        _isSearching = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchLocations = [];
        _searchPlacemarks = [];
        _isSearching = false;
      });
    }
  }

  void _selectSearchResult(int index) {
    final loc = _searchLocations[index];
    final pm = index < _searchPlacemarks.length ? _searchPlacemarks[index] : null;
    _addMarker(LatLng(loc.latitude, loc.longitude), pm);
    setState(() {
      _showSearch = false;
      _searchController.clear();
      _searchLocations = [];
      _searchPlacemarks = [];
    });
  }

  // ── Save ───────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (_markerAlarms.isEmpty) return;
    widget.onAlarmsAdded(_markerAlarms.values.toList());
    Navigator.pop(context);
    try {
      await InAppReview.instance.requestReview();
    } catch (_) {}
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Press map to mark locations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => setState(() {
              _showSearch = !_showSearch;
              if (!_showSearch) {
                _searchController.clear();
                _searchLocations = [];
              }
            }),
          ),
          if (_markerAlarms.isNotEmpty)
            TextButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: LatLng(47.3769, 8.5417),
              zoom: _defaultZoom,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: true,
            markers: _markers,
            onMapCreated: (controller) {
              _mapController = controller;
              _moveToCurrentLocation();
            },
            onLongPress: _onLongPress,
          ),
          if (_showSearch) _buildSearchOverlay(),
        ],
      ),
    );
  }

  Widget _buildSearchOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        elevation: 4,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search for locations',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() {
                      _showSearch = false;
                      _searchController.clear();
                      _searchLocations = [];
                    }),
                  ),
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: _onSearchChanged,
              ),
            ),
            if (_isSearching) const LinearProgressIndicator(),
            if (_searchLocations.isNotEmpty)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _searchLocations.length,
                  itemBuilder: (context, index) {
                    final pm = index < _searchPlacemarks.length
                        ? _searchPlacemarks[index]
                        : const Placemark();
                    final name = pm.name?.isNotEmpty == true
                        ? pm.name!
                        : pm.locality ?? 'Unknown';
                    final address = [
                      pm.thoroughfare,
                      pm.locality,
                      pm.administrativeArea,
                      pm.country,
                    ].where((s) => s != null && s.isNotEmpty).join(', ');
                    return ListTile(
                      dense: true,
                      title: Text(name),
                      subtitle: Text(
                        address,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () => _selectSearchResult(index),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
