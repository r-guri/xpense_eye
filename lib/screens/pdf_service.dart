import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfService {

  static Future generate(
      String tripName,
      List expenses
      ) async {

    final pdf = pw.Document();

    pdf.addPage(

      pw.Page(

        build:(context){

          return pw.Column(

            crossAxisAlignment:
            pw.CrossAxisAlignment.start,

            children:[

              pw.Text(
                tripName,
                style:pw.TextStyle(
                  fontSize:24,
                  fontWeight:pw.FontWeight.bold,
                ),
              ),

              pw.SizedBox(height:20),

              ...expenses.map(
                (e)=> pw.Text(
                  "${e['title']}  ₹${e['amount']}",
                ),
              )
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout:(format)=> pdf.save(),
    );
  }
}