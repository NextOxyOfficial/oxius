import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/rideshare_models.dart';
import '../../services/rideshare_service.dart';
import '../../services/translation_service.dart';
import 'rideshare_page_header.dart';
import 'rideshare_vehicle_catalog.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';

class RideshareHistoryScreen extends StatefulWidget {
  final bool asDriver;

  const RideshareHistoryScreen({
    super.key,
    this.asDriver = false,
  });

  @override
  State<RideshareHistoryScreen> createState() => _RideshareHistoryScreenState();
}

class _RideshareHistoryScreenState extends State<RideshareHistoryScreen> {
  static const String _bdtSymbol = '\u09F3';
  final TranslationService _ts = TranslationService();
  List<Ride> _rides = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _currentPage = 1;
  static const int _pageSize = 20;
  String? _error;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadRides();
    _scrollController.addListener(_onScroll);
    _ts.addListener(_onTranslationsChanged);
  }

  @override
  void dispose() {
    _ts.removeListener(_onTranslationsChanged);
    _scrollController.dispose();
    super.dispose();
  }

  String t(String key, {required String fallback}) =>
      _ts.t(key, fallback: fallback);

  void _onTranslationsChanged() {
    if (mounted) setState(() {});
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadRides() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _currentPage = 1;
      _hasMore = true;
      _rides = [];
    });

    final result = await RideshareService.listRides(
      asDriver: widget.asDriver,
      page: 1,
      pageSize: _pageSize,
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result.success) {
          _rides = result.data ?? [];
          _hasMore = _rides.length >= _pageSize;
          _currentPage = 1;
        } else {
          _error = result.message;
        }
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;

    setState(() => _isLoadingMore = true);

    final nextPage = _currentPage + 1;
    final result = await RideshareService.listRides(
      asDriver: widget.asDriver,
      page: nextPage,
      pageSize: _pageSize,
    );

    if (mounted) {
      setState(() {
        _isLoadingMore = false;
        if (result.success) {
          final newRides = result.data ?? [];
          _rides.addAll(newRides);
          _hasMore = newRides.length >= _pageSize;
          if (newRides.isNotEmpty) _currentPage = nextPage;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            RidesharePageHeader(
              title: widget.asDriver
                  ? t('rideshare_history_driver_title', fallback: 'ড্রাইভার ট্রিপ')
                  : t('rideshare_history_title', fallback: 'আমার ট্রিপ'),
              subtitle: _rides.isEmpty
                  ? null
                  : '${_rides.length}টি ট্রিপ',
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: AdsyLoadingIndicator());
    }

    return AdsyRefreshIndicator(
      onRefresh: _loadRides,
      child: _rides.isNotEmpty
          ? ListView.builder(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 4, bottom: 12),
              itemCount: _rides.length + (_isLoadingMore || _hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _rides.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: _isLoadingMore
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: AdsyLoadingIndicator(strokeWidth: 2),
                            )
                          : TextButton(
                              onPressed: _loadMore,
                              child: Text(
                                t('rideshare_load_more', fallback: 'আরও দেখুন'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF6366F1),
                                ),
                              ),
                            ),
                    ),
                  );
                }
                return _buildRideCard(_rides[index]);
              },
            )
          : ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.62,
                  child: Center(
                    child: _error != null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Colors.red.shade300,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _error!,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF64748B),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _loadRides,
                                child:
                                    Text(t('try_again', fallback: 'আবার চেষ্টা করুন')),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.history_rounded,
                                  size: 48,
                                  color: Color(0xFF94A3B8),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                t('rideshare_no_rides_title',
                                    fallback: 'এখনো কোনো রাইড নেই'),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF1E293B),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                widget.asDriver
                                    ? t('rideshare_no_rides_driver',
                                        fallback:
                                            'Your completed trips will appear here')
                                    : t('rideshare_no_rides_passenger',
                                        fallback:
                                            'Your ride history will appear here'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  /// One trip, as a plain row.
  ///
  /// The old design wrapped every trip in a bordered card with a coloured
  /// header band, so a list of cancelled rides read as a wall of red panels.
  /// The status belongs on the status, not on the whole trip.
  Widget _buildRideCard(Ride ride) {
    final vehicle = RideVehicle.byKey(ride.vehicle?.vehicleType);
    final statusColor = _getStatusColor(ride.status);
    final fare = ride.finalFare ?? ride.fareEstimate;
    final facts = <String>[
      if (ride.distanceKm > 0) '${ride.distanceKm.toStringAsFixed(1)} km',
      if (ride.etaDisplay.trim().isNotEmpty) ride.etaDisplay,
      _paymentMethodLabel(ride.paymentMethod),
    ];
    final counterpartName = widget.asDriver
        ? ride.riderName
        : (ride.assignedDriver?.userName ?? '');

    return InkWell(
      onTap: () => _showTripDetails(ride),
      child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 34, child: vehicle.artwork(size: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.dropAddress.trim().isNotEmpty
                              ? ride.dropAddress
                              : vehicle.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatDate(ride.requestedAt)} · '
                          '${_formatTime(ride.requestedAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$_bdtSymbol${fare.toStringAsFixed(0)}',
                        style: GoogleFonts.inter(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        ride.statusDisplay,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: _buildRouteRail(ride),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 46),
                child: Text(
                  [
                    ...facts,
                    if (counterpartName.trim().isNotEmpty) counterpartName,
                  ].join('  ·  '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 11.5,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1, thickness: 1, color: Color(0xFFF3F5F8)),
      ],
      ),
    );
  }

  /// One trip, in full, as a plain sheet — rows and hairlines, no cards.
  void _showTripDetails(Ride ride) {
    final vehicle = RideVehicle.byKey(ride.vehicle?.vehicleType);
    final statusColor = _getStatusColor(ride.status);
    final fare = ride.finalFare ?? ride.fareEstimate;
    final counterpartName = widget.asDriver
        ? ride.riderName
        : (ride.assignedDriver?.userName ?? '');
    final plate = ride.vehicle?.registrationNumber ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  SizedBox(width: 36, child: vehicle.artwork(size: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ride.statusDisplay,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        Text(
                          '${_formatDate(ride.requestedAt)} · '
                          '${_formatTime(ride.requestedAt)}',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$_bdtSymbol${fare.toStringAsFixed(0)}',
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildRouteRail(ride),
              const SizedBox(height: 16),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              _detailRow(t('rideshare_distance', fallback: 'দূরত্ব'),
                  '${ride.distanceKm.toStringAsFixed(1)} km'),
              _detailRow(t('rideshare_eta', fallback: 'সময়'),
                  ride.etaDisplay.trim().isNotEmpty ? ride.etaDisplay : '—'),
              _detailRow(t('rideshare_payment_method', fallback: 'পেমেন্ট'),
                  _paymentMethodLabel(ride.paymentMethod)),
              if (counterpartName.trim().isNotEmpty)
                _detailRow(
                    widget.asDriver ? 'যাত্রী' : 'ড্রাইভার', counterpartName),
              if (plate.trim().isNotEmpty) _detailRow('গাড়ি', plate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
                fontSize: 13, color: const Color(0xFF94A3B8)),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Pickup and drop joined by the dotted rail, so the eye reads them as one
  /// journey instead of two unrelated addresses.
  Widget _buildRouteRail(Ride ride) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
              ),
            ),
            Container(
              width: 1.5,
              height: 18,
              margin: const EdgeInsets.symmetric(vertical: 2),
              color: const Color(0xFFE2E8F0),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                ride.pickupAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF475569),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                ride.dropAddress,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return const Color(0xFF10B981);
      case 'cancelled':
        return const Color(0xFFEF4444);
      case 'in_progress':
        return const Color(0xFF6366F1);
      case 'searching_driver':
      case 'accepted':
      case 'driver_arriving':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF64748B);
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour > 12 ? date.hour - 12 : date.hour;
    final period = date.hour >= 12 ? 'PM' : 'AM';
    return '${hour == 0 ? 12 : hour}:${date.minute.toString().padLeft(2, '0')} $period';
  }

  String _paymentMethodLabel(String paymentMethod) {
    switch (paymentMethod.trim().toLowerCase()) {
      case 'cash':
        return t('rideshare_payment_cash', fallback: 'ক্যাশ');
      case 'wallet':
        return t('rideshare_payment_wallet', fallback: 'ওয়ালেট');
      default:
        if (paymentMethod.trim().isEmpty) {
          return t('rideshare_not_available', fallback: '—');
        }
        return paymentMethod.replaceAll('_', ' ');
    }
  }
}
