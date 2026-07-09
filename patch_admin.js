const fs = require('fs');
const path = 'g:/EduTrack/lib/screens/admin_dashboard.dart';
let code = fs.readFileSync(path, 'utf8');

const regex = /Widget _buildBillingItem\(QueryDocumentSnapshot doc\) \{([\s\S]*?)return Container\(/;
const match = code.match(regex);
if(match) {
    let newLogic = `Widget _buildBillingItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final studentId = data['studentId'] ?? '';
    final origName = data['studentName'] ?? 'N/A';
    final origCardId = data['studentCardId'] ?? 'N/A';
    final origMajor = data['major'] ?? 'Mặc định';
    int origCredits = data['creditsCount'] ?? 0;
    int origCourses = data['coursesCount'] ?? 0;
    final total = data['totalAmount'] ?? 0;
    final status = data['status'] ?? 'unpaid';
    final coursesList = (data['courses'] as List<dynamic>?) ?? [];
    final proofUrl = data['proofUrl'] as String?;
    final isPaid = status == 'paid';
    final isPending = status == 'pending_verification';
    
    if (origCredits == 0 && origCourses == 0 && coursesList.isNotEmpty) {
      origCourses = coursesList.length;
      origCredits = coursesList.fold(0, (sum, item) => sum + ((item as Map<String, dynamic>)['credits'] as int? ?? 0));
    }
    
    Widget buildUI(String name, String cardId, String major, int credits, int courses) {
      return Container(`;
    
    code = code.replace(regex, newLogic);
    
    const endRegex = /          \),\n        \),\n      \);\n    \}\n/;
    const endMatch = code.match(endRegex);
    if(endMatch) {
      const replacement = `          ),
        ),
      );
    }
    
    if (origName != 'N/A' && origCardId != 'N/A') {
      return buildUI(origName, origCardId, origMajor, origCredits, origCourses);
    }
    
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(studentId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return buildUI(origName, origCardId, origMajor, origCredits, origCourses);
        }
        final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
        final fName = userData['fullName'] ?? origName;
        final fCardId = userData['studentId'] ?? origCardId;
        final fMajor = userData['major'] ?? origMajor;
        return buildUI(fName, fCardId, fMajor, origCredits, origCourses);
      },
    );
  }
`;
      // We must only replace the LAST occurrence of the endRegex within the function, 
      // but actually since we only call replace once, it replaces the first occurrence!
      // This is dangerous if there is another matching endRegex before it.
}
EOF
