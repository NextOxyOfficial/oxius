import 'package:flutter/material.dart';
import 'package:oxius_native/widgets/common/adsy_toast.dart';
import 'package:oxius_native/widgets/common/adsy_loading.dart';
import '../../../models/eshop_manager_models.dart';
import '../../../services/eshop_manager_service.dart';
import '../../../services/translation_service.dart';

/// Edit an existing order's items — change quantities, remove items, or add
/// more of the seller's products. Saves via the `orders/<id>/update/` endpoint
/// (quantity 0 removes, a new product id adds).
class EditOrderSheet extends StatefulWidget {
  final ShopOrder order;
  final List<ShopProduct> products;
  final Future<void> Function() onSaved;

  const EditOrderSheet({
    super.key,
    required this.order,
    required this.products,
    required this.onSaved,
  });

  @override
  State<EditOrderSheet> createState() => _EditOrderSheetState();
}

class _OrderLine {
  final String productId;
  final String name;
  final double unitPrice;
  int qty;
  _OrderLine(this.productId, this.name, this.unitPrice, this.qty);
}

class _EditOrderSheetState extends State<EditOrderSheet> {
  final TranslationService _i18n = TranslationService();
  String _t(String key, String fallback) =>
      _i18n.translate(key, fallback: fallback);

  final List<_OrderLine> _lines = [];
  late final Set<String> _originalIds;
  bool _saving = false;

  static const _green = Color(0xFF059669);

  @override
  void initState() {
    super.initState();
    final items = widget.order.items ?? [];
    for (final it in items) {
      _lines.add(_OrderLine(it.productId, it.productName, it.price, it.quantity));
    }
    _originalIds = items.map((e) => e.productId).toSet();
  }

  double get _total =>
      _lines.fold<double>(0, (s, l) => s + l.unitPrice * l.qty);

  void _addProduct(ShopProduct p) {
    final i = _lines.indexWhere((l) => l.productId == p.id);
    setState(() {
      if (i >= 0) {
        _lines[i].qty += 1;
      } else {
        _lines.add(_OrderLine(p.id, p.name, p.price, 1));
      }
    });
  }

  void _inc(_OrderLine l) => setState(() => l.qty += 1);
  void _dec(_OrderLine l) => setState(() {
        if (l.qty > 1) {
          l.qty -= 1;
        } else {
          _lines.remove(l);
        }
      });
  void _remove(_OrderLine l) => setState(() => _lines.remove(l));

  Future<void> _showAddPicker() async {
    final query = ValueNotifier<String>('');
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(ctx).size.height * 0.7,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                child: TextField(
                  autofocus: false,
                  onChanged: (v) => query.value = v.toLowerCase().trim(),
                  decoration: InputDecoration(
                    hintText: _t('eshop_search_product', 'প্রোডাক্ট খুঁজুন...'),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    isDense: true,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (context, q, _) {
                    final list = widget.products
                        .where((p) =>
                            q.isEmpty || p.name.toLowerCase().contains(q))
                        .toList();
                    if (list.isEmpty) {
                      return Center(
                        child: Text(
                          _t('eshop_no_products_found', 'কোনো প্রোডাক্ট নেই'),
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(2, 0, 2, 12),
                      itemCount: list.length,
                      separatorBuilder: (_, __) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, i) {
                        final p = list[i];
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.inventory_2_outlined,
                              color: _green, size: 20),
                          title: Text(p.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w600)),
                          subtitle: Text('৳${p.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                  fontSize: 12, color: _green)),
                          trailing:
                              const Icon(Icons.add_circle_outline, color: _green),
                          onTap: () {
                            _addProduct(p);
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    final currentIds = _lines.map((l) => l.productId).toSet();
    final items = <Map<String, dynamic>>[
      for (final l in _lines) {'product': l.productId, 'quantity': l.qty},
      // Items that were removed: send quantity 0 so the backend deletes them.
      for (final id in _originalIds)
        if (!currentIds.contains(id)) {'product': id, 'quantity': 0},
    ];

    final result = await EshopManagerService.updateOrderItems(
      orderId: widget.order.id,
      items: items,
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (result['success'] == true) {
      await widget.onSaved();
      if (!mounted) return;
      Navigator.pop(context);
      AdsyToast.success(
          context, _t('eshop_order_updated', 'অর্ডার আপডেট হয়ে গেছে'));
    } else {
      final backendMsg = (result['message'] as String?)?.trim();
      AdsyToast.error(
          context,
          (backendMsg != null && backendMsg.isNotEmpty)
              ? backendMsg
              : _t('eshop_order_update_failed', 'অর্ডার আপডেট করা গেল না'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.92,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: Row(
                  children: [
                    const Icon(Icons.edit_note_rounded, color: _green, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _t('eshop_edit_order', 'অর্ডার এডিট'),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      '#${widget.order.orderNumber ?? ''}',
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              // Items list
              Expanded(
                child: _lines.isEmpty
                    ? Center(
                        child: Text(
                          _t('eshop_no_items_left',
                              'কোনো আইটেম নেই — প্রোডাক্ট অ্যাড করুন'),
                          style: const TextStyle(color: Color(0xFF94A3B8)),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                        itemCount: _lines.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1, color: Color(0xFFF1F5F9)),
                        itemBuilder: (context, i) => _lineRow(_lines[i]),
                      ),
              ),
              // Add product button
              Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 6),
                child: OutlinedButton.icon(
                  onPressed: _showAddPicker,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: Text(_t('eshop_add_product_to_order', 'প্রোডাক্ট অ্যাড করুন')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _green,
                    side: const BorderSide(color: _green),
                    minimumSize: const Size(double.infinity, 46),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              // Total + Save
              Container(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 16),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(_t('eshop_items_total', 'আইটেম টোটাল'),
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF64748B))),
                        const Spacer(),
                        Text('৳${_total.toStringAsFixed(0)}',
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                                color: _green)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saving ? null : _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0,
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: AdsyLoadingIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(
                                _t('eshop_save_order', 'অর্ডার সেভ করুন'),
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w700),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _lineRow(_OrderLine l) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1F2937))),
                const SizedBox(height: 2),
                Text('৳${l.unitPrice.toStringAsFixed(0)} × ${l.qty}',
                    style: const TextStyle(
                        fontSize: 11.5, color: Color(0xFF64748B))),
              ],
            ),
          ),
          // Quantity stepper
          _stepBtn(Icons.remove_rounded, () => _dec(l)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text('${l.qty}',
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w800)),
          ),
          _stepBtn(Icons.add_rounded, () => _inc(l)),
          const SizedBox(width: 4),
          InkWell(
            onTap: () => _remove(l),
            borderRadius: BorderRadius.circular(8),
            child: const Padding(
              padding: EdgeInsets.all(6),
              child: Icon(Icons.delete_outline,
                  size: 20, color: Color(0xFFDC2626)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF334155)),
      ),
    );
  }
}
