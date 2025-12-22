// import 'package:bitnet/backbone/helper/theme/theme.dart';
// import 'package:bitnet/models/mempool_models/mempool_model.dart';
// import 'package:bitnet/pages/mempool/controller/home_controller.dart';
// import 'package:flutter/material.dart';
//
// class SocketDataWidget extends StatefulWidget {
//   MempoolBlocks mempoolBlocks;
//   String mins;
//   String? txId;
//   bool singleTx = false;
//   int? index;
//
//   SocketDataWidget(
//       {Key? key,
//       required this.mempoolBlocks,
//       required this.mins,
//       required this.singleTx,
//       this.txId,
//       this.index})
//       : super(key: key);
//
//   @override
//   State<SocketDataWidget> createState() => _SocketDataWidgetState();
// }
//
// class _SocketDataWidgetState extends State<SocketDataWidget> {
//   @override
//   Widget build(BuildContext context) {
//     // final controller = Get.find<TransactionController>();
//     return Column(
//       children: [
//         Text(
//           "",
//           style: const TextStyle(
//               fontSize: 20,
//               fontWeight: FontWeight.w700,
//               color: Color(0xdd1bd8f4)),
//         ),
//         const SizedBox(height: AppTheme.elementSpacing),
//         Container(
//           height: AppTheme.cardPadding * 6,
//           width: AppTheme.cardPadding * 6, //MediaQuery.of(context).size.height * 0.2,
//           margin: const EdgeInsets.only(top: 40, left: 10, right: 10),
//           decoration: BoxDecoration(
//               boxShadow: [
//                 BoxShadow(
//                     color: const Color(0xffA24132).withOpacity(0.5),
//                     offset: const Offset(-16, -16)),
//               ],
//               borderRadius: BorderRadius.circular(20),
//               color: const Color(0xffA24132)),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Text(
//                 '~${widget.mempoolBlocks.medianFee?.toStringAsFixed(0)} sat/vB',
//                 style: const TextStyle(fontSize: 14, color: Colors.white),
//               ),
//               // const SizedBox(height: 10),
//               // Text(
//               //   '${widget.mempoolBlocks.feeRange?.first.toStringAsFixed(0)}  - ${widget.mempoolBlocks.feeRange?.last.toStringAsFixed(0)} sat/vB',
//               //   style: TextStyle(
//               //     fontSize: 14,
//               //     color: Colors.yellow.shade700,
//               //   ),
//               // ),
//               const SizedBox(height: AppTheme.elementSpacing * 0.5),
//               Text(
//                 '${(widget.mempoolBlocks.blockSize! / 1000000).toStringAsFixed(2)} MB',
//                 style: const TextStyle(
//                     fontSize: 20,
//                     color: Colors.white,
//                     fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: AppTheme.elementSpacing * 0.5),
//               // mempoolBlocks.nTx
//               //      .toString()
//               //      .length <=
//               //      3
//               //      ?
//               Text(
//                 '${formatPrice(widget.mempoolBlocks.nTx)} transactions',
//                 style: const TextStyle(fontSize: 14, color: Colors.white),
//                 overflow: TextOverflow.ellipsis,
//               ),
//               // : Text(
//               // '${mempoolBlocks.nTx!} Transaction',
//               // style: const TextStyle(
//               //     fontSize: 14, color: Colors.white), overflow: TextOverflow.ellipsis),
//               const SizedBox(height: AppTheme.elementSpacing * 0.5),
//               Text(
//                 'In ~${widget.mins} minutes',
//                 style: const TextStyle(fontSize: 14, color: Colors.white),
//               ),
//             ],
//           ),
//         ),
//         //  Icon(Icons.arrow_drop_down, size: 50.0),
//         // :
//         widget.index == 1
//             ? const Icon(
//                 Icons.arrow_drop_down_rounded,
//                 size: AppTheme.cardPadding * 2.5,
//               )
//             : const SizedBox(
//                 height: AppTheme.cardPadding * 2.5,
//               ),
//       ],
//     );
//   }
// }
