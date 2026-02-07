import 'package:flutter/material.dart';

import '../../widgets/bottom_navigation.dart';

class NewQuotationScreen extends StatefulWidget {
  final int roleId;
  final String roleName;

  const NewQuotationScreen({
    super.key,
    required this.roleId,
    required this.roleName,
  });

  @override
  State<NewQuotationScreen> createState() => _NewQuotationScreenState();
}

class _NewQuotationScreenState extends State<NewQuotationScreen> {
  static const Color midGreen = Color(0xFF1F8B00);
  bool _moreOpen = false;
  int _navIndex = 0;

  bool isSearchExpanded = false;
  bool showProductList = false;
  bool showOverlay = false;

  final TextEditingController searchCtrl = TextEditingController();

  // ✅ products list (demo)
  final List<ProductItem> _allProducts = const [
    ProductItem(name: 'Apple MacBook Air M1', price: '₹ 62,990'),
    ProductItem(name: 'ASUS ROG Strix G13CHR', price: '₹ 1,29,990'),
    ProductItem(name: 'Qubo Smart 360', price: '₹ 1,489'),
    ProductItem(name: 'HP Pavilion', price: '₹ 78,999'),
    ProductItem(name: 'Dell Inspiron 15', price: '₹ 54,990'),
    ProductItem(name: 'Lenovo ThinkPad', price: '₹ 92,990'),
  ];

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  List<ProductItem> get _filteredProducts {
    final q = searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _allProducts;
    return _allProducts.where((p) => p.name.toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      /// APP BAR
      appBar: AppBar(
        backgroundColor: midGreen,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New Quotation',
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Navigator.pushNamed(
              //   context,
              //   AppRoutes.NotificationScreen,
              //   arguments: NotificationArguments(
              //     roleId: widget.roleId,
              //     roleName: widget.roleName,
              //   ),
              // );
            },
            icon: const Icon(Icons.notifications_none, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ],
      ),

      /// BODY
      body: Stack(
        clipBehavior: Clip.none, // ✅ important (prevents flash + clipping)
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 140),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Personal Information',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),

                _input('Lead ID', 'L-001'),
                _input('Quotation ID', 'QTN-001'),
                _dateInput('Quotation Date', '12-01-2025'),
                _dateInput('Expiration Date', '12-01-2025'),

                const SizedBox(height: 12),

                /// ITEM CARD (STATIC, MULTIPLE)
                _itemCard(),
                _itemCard(),

                const SizedBox(height: 16),

                /// GENERATE BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: midGreen,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {},
                    child: const Text(
                      'Generate',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          /// ✅ OVERLAY (tap outside closes dropdown + collapses search)
          if (showOverlay)
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  FocusScope.of(context).unfocus();
                  setState(() {
                    showOverlay = false;
                    showProductList = false;
                    isSearchExpanded = false;
                  });
                },
                child: Container(color: Colors.black.withOpacity(0.06)),
              ),
            ),

          /// ✅ PRODUCT LIST PANEL (ABOVE SEARCH BAR)
          if (showProductList)
            Positioned(
              left: 0,
              right: 0,
              bottom: 80, // ✅ above search bar
              child: _productPanel(), // now filtered
            ),

          /// ✅ SEARCH BAR (fixed left/right = no red flash)
          Positioned(
            left: 16,
            right: 16,
            bottom: 20,
            child: Align(
              alignment: Alignment.centerRight,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOut,
                height: 48,
                width: isSearchExpanded ? double.infinity : 48,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: midGreen,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    /// ✅ SEARCH ICON
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          // ✅ One click: expand + show list above
                          isSearchExpanded = true;
                          showOverlay = true;
                          showProductList = true;
                        });
                      },
                      child: const Icon(
                        Icons.search,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    if (isSearchExpanded) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: searchCtrl,
                          autofocus: true,
                          onChanged: (_) {
                            setState(() {
                              // ✅ triggers product list filter refresh
                            });
                          },
                          decoration: const InputDecoration(
                            hintText: 'Search',
                            hintStyle: TextStyle(color: Colors.white70),
                            border: InputBorder.none,
                          ),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            isSearchExpanded = false;
                            showOverlay = false;
                            showProductList = false;
                            searchCtrl.clear();
                          });
                        },
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      bottomNavigationBar: CrackteckBottomSwitcher(
        isMoreOpen: _moreOpen,
        currentIndex: _navIndex,
        roleId: widget.roleId,
        roleName: widget.roleName,
        onHome: () {},
        onProfile: () {},
        onMore: () => setState(() => _moreOpen = true),
        onLess: () => setState(() => _moreOpen = false),
        onLeads: () {},
        onFollowUp: () {},
        onMeeting: () {},
        onQuotation: () {},
      ),
    );
  }

  /// INPUT FIELD
  Widget _input(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// DATE FIELD
  Widget _dateInput(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        initialValue: value,
        readOnly: true,
        decoration: InputDecoration(
          labelText: label,
          suffixIcon: const Icon(Icons.calendar_today, color: midGreen),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  /// ITEM CARD
  Widget _itemCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _row('Item Description', 'Laptop'),
          _row('HSN Code', '8471'),
          _row('Quantity', '2'),
          _row('Unit Price', '50,000'),
          _row('Tax (%)', '18%'),
          _row('Total', '1,18,000', bold: true),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _actionBtn(
                  'Edit',
                  Icons.edit,
                  Colors.orange.shade100,
                  Colors.orange,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  'Delete',
                  Icons.delete,
                  Colors.red.shade100,
                  Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// ROW TEXT
  Widget _row(String k, String v, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(color: Colors.black54)),
          Text(v, style: TextStyle(fontWeight: bold ? FontWeight.w700 : null)),
        ],
      ),
    );
  }

  /// ACTION BUTTON
  Widget _actionBtn(String t, IconData i, Color bg, Color fg) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, size: 16, color: fg),
            const SizedBox(width: 6),
            Text(t, style: TextStyle(color: fg)),
          ],
        ),
      ),
    );
  }

  /// ✅ PRODUCT PANEL (filtered by searchCtrl)
  Widget _productPanel() {
    final list = _filteredProducts;

    return Material(
      color: Colors.transparent,
      child: Container(
        height: 240,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.12),
              blurRadius: 14,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: list.isEmpty
            ? const Center(
                child: Text(
                  "No products found",
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              )
            : ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return _ProductCard(
                    name: p.name,
                    price: p.price,
                    roleId: widget.roleId,
                    roleName: widget.roleName,
                  );
                },
              ),
      ),
    );
  }
}

/// ✅ Simple product model
class ProductItem {
  final String name;
  final String price;

  const ProductItem({required this.name, required this.price});
}

/// PRODUCT CARD
class _ProductCard extends StatelessWidget {
  final String name;
  final String price;
  final int roleId;
  final String roleName;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.roleId,
    required this.roleName,
  });

  static const Color midGreen = Color(0xFF1F8B00);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black12),
        color: Colors.white,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              "https://images.unsplash.com/photo-1587202372775-e229f172b9d7?auto=format&fit=crop&w=600&q=80",
              height: 70,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.computer, size: 48),
            ),
          ),
          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
          Text(price, style: const TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: midGreen),
              onPressed: () {
                // Navigator.pushNamed(
                //   context,
                //   AppRoutes.ProductScreen,
                //   arguments: SalesproductArguments(
                //     roleId: roleId,
                //     roleName: roleName,
                //   ),
                // );
              },
              child: const Text('View', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
