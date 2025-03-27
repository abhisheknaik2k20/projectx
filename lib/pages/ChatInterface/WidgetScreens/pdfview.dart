// ignore_for_file: non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pinput/pinput.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';

class PDFViewer extends StatefulWidget {
  final Map<String, dynamic> data;
  const PDFViewer({required this.data, super.key});

  @override
  State<PDFViewer> createState() => _PDFViewerState();
}

class _PDFViewerState extends State<PDFViewer> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final _textEditingController = TextEditingController();

  final _pdfViewerController = PdfViewerController();

  void SetPage(int pagenum, int totalpages) {
    _textEditingController.setText("$pagenum / $totalpages");
  }

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.teal.shade700,
            borderRadius: const BorderRadius.all(
              Radius.circular(10),
            ),
          ),
          child: IconButton(
            icon: const Icon(
              Icons.arrow_back_sharp,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        centerTitle: true,
        title: Text(
          widget.data['filename'],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontFamily: 'PT Sans',
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.info,
              color: Colors.white,
            ),
            onPressed: () {
              _showBottomSheetDetails(widget.data, context);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          pdfAppbar(),
          Expanded(
            child: SfTheme(
              data: SfThemeData(
                pdfViewerThemeData: SfPdfViewerThemeData(
                  paginationDialogStyle: PdfPaginationDialogStyle(
                    backgroundColor: Colors.grey.shade800,
                    headerTextStyle: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 40,
                        fontFamily: 'Anton'),
                    inputFieldTextStyle: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 20,
                        fontFamily: 'PT Sans'),
                    validationTextStyle: const TextStyle(
                        color: Colors.red, fontSize: 20, fontFamily: 'PT Sans'),
                    okTextStyle: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PT Sans'),
                    cancelTextStyle: TextStyle(
                        color: Colors.teal.shade400,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'PT Sans'),
                  ),
                  scrollHeadStyle: PdfScrollHeadStyle(
                    backgroundColor: Colors.teal.shade600,
                    pageNumberTextStyle: TextStyle(
                      color: Colors.teal.shade600,
                      fontFamily: 'Anton',
                    ),
                  ),
                  scrollStatusStyle: PdfScrollStatusStyle(
                    backgroundColor: Colors.grey.shade400,
                    pageInfoTextStyle: TextStyle(
                      color: Colors.grey.shade600,
                      fontFamily: 'Anton',
                    ),
                  ),
                  progressBarColor: Colors.teal.shade300,
                ),
              ),
              child: SfPdfViewer.network(
                widget.data['message'],
                controller: _pdfViewerController,
                canShowScrollStatus: false,
                onPageChanged: (details) {
                  SetPage(_pdfViewerController.pageNumber,
                      _pdfViewerController.pageCount);
                },
                onDocumentLoaded: (details) {
                  SetPage(_pdfViewerController.pageNumber,
                      _pdfViewerController.pageCount);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showBottomSheetDetails(
      Map<String, dynamic> data, BuildContext context) {
    _scaffoldKey.currentState!.showBottomSheet(
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ), (context) {
      return Container(
        padding: const EdgeInsets.all(
          20,
        ),
        height: 550,
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(40),
            topRight: Radius.circular(40),
          ),
        ),
        child: Column(
          children: [
            Container(
              height: 2,
              width: 100,
              decoration: const BoxDecoration(
                color: Colors.white,
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            const Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Text(
                  'Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontFamily: 'PT Sans',
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.info,
                  size: 50,
                  color: Colors.teal.shade400,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File Name',
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontFamily: 'PT Sans',
                      ),
                    ),
                    Text(
                      data['filename'],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PT Sans',
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.calendar_month,
                  size: 50,
                  color: Colors.teal.shade400,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('MMMM-dd').format(
                        data['timestamp'].toDate(),
                      ),
                      style: const TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontFamily: 'PT Sans',
                      ),
                    ),
                    Text(
                      DateFormat('EEEE yyyy').format(
                        data['timestamp'].toDate(),
                      ),
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PT Sans',
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.picture_as_pdf,
                  size: 50,
                  color: Colors.teal.shade400,
                ),
                const SizedBox(
                  width: 10,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Type',
                      style: TextStyle(
                        fontSize: 25,
                        color: Colors.white,
                        fontFamily: 'PT Sans',
                      ),
                    ),
                    Text(
                      data['type'],
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.teal.shade400,
                        fontFamily: 'PT Sans',
                      ),
                    )
                  ],
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  Icons.backup,
                  size: 50,
                  color: Colors.teal.shade400,
                ),
                const SizedBox(
                  width: 8,
                ),
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.only(
                      left: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'BackUp URL',
                          style: TextStyle(
                            fontSize: 25,
                            color: Colors.white,
                            fontFamily: 'PT Sans',
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Text(
                            data['message'],
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.teal.shade400,
                              fontFamily: 'PT Sans',
                            ),
                            softWrap: true,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 5,
                right: 5,
                bottom: 10,
              ),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.download,
                        size: 40,
                        color: Colors.teal.shade500,
                      ),
                    ),
                    const Text(
                      "Save?",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontFamily: 'PT Sans',
                      ),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      );
    });
  }

  Widget pdfAppbar() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade700,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _pdfViewerController.previousPage();
              SetPage(_pdfViewerController.pageNumber,
                  _pdfViewerController.pageCount);
            },
            icon: const Icon(
              Icons.arrow_back_ios_new,
              color: Colors.white,
            ),
          ),
          IconButton(
            onPressed: () {
              _pdfViewerController.nextPage();
              SetPage(_pdfViewerController.pageNumber,
                  _pdfViewerController.pageCount);
            },
            icon: Transform.flip(
              flipX: true,
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(
            width: 20,
          ),
          Container(
            width: 75,
            alignment: Alignment.center,
            padding: const EdgeInsets.only(
              left: 10,
            ),
            decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: const BorderRadius.all(
                  Radius.circular(10),
                )),
            child: TextFormField(
              readOnly: true,
              controller: _textEditingController,
              cursorColor: Colors.white,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontFamily: 'PT Sans',
              ),
              decoration: const InputDecoration(
                enabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                border: InputBorder.none,
              ),
            ),
          )
        ],
      ),
    );
  }
}
