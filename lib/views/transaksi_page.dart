// import 'package:flutter/material.dart';

// class TransaksiPage extends StatelessWidget {
//   const TransaksiPage({super.key});

//   final List<Map<String, dynamic>> transaksiList = const [
//     {'menu': 'Kopi Hitam', 'jumlah': 2, 'total': 10000},
//     {'menu': 'Indomie Goreng', 'jumlah': 1, 'total': 12000},
//   ];

//   @override
//   Widget build(BuildContext context) {
//     int totalPendapatan = transaksiList.fold(0, (sum, item) => sum + item['total']);

//     return Scaffold(
//       appBar: AppBar(title: const Text("Transaksi Hari Ini")),
//       body: Column(
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: transaksiList.length,
//               itemBuilder: (context, index) {
//                 final item = transaksiList[index];
//                 return ListTile(
//                   title: Text(item['menu']),
//                   subtitle: Text("Jumlah: ${item['jumlah']}"),
//                   trailing: Text("Rp ${item['total']}"),
//                 );
//               },
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.all(16),
//             child: Text("Total Pendapatan Hari Ini: Rp $totalPendapatan",
//               style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//             ),
//           )
//         ],
//       ),
//     );
//   }
// }
