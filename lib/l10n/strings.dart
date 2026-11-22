/// Language choices. Roman Urdu is the default; English is the option.
enum AppLang { romanUrdu, english }

/// A compact bilingual string table. Each getter returns Roman Urdu or English
/// depending on [lang]. Numbers and icons carry most of the meaning, so this
/// set stays small and focused on the labels the screens actually show.
class Strings {
  final AppLang lang;
  const Strings(this.lang);

  String _(String ur, String en) => lang == AppLang.english ? en : ur;

  // App
  String get appName => 'Doodh Hisaab';

  // Bottom navigation
  String get navToday => _('Aaj ka Route', 'Today');
  String get navCustomers => _('Customers', 'Customers');
  String get navHisaab => _('Hisaab', 'Reports');

  // Today screen
  String get todayTitle => _('Aaj ka Route', "Today's Route");
  String get subah => _('Subah', 'Morning');
  String get shaam => _('Shaam', 'Evening');
  String get naga => _('Naga', 'Naga');
  String get extra => _('+ Extra', '+ Extra');
  String get khula => _('Khula', 'Loose');
  String get roundKhatam => _('Round khatam', 'Close round');
  String get payment => _('Payment', 'Payment');
  String get delivered => _('Diya', 'Delivered');
  String get undo => _('Wapas', 'Undo');

  // Totals
  String get todaysTotal => _('Aaj ka total', "Today's total");
  String get looseLabel => _('Khula', 'Loose');

  // Customers
  String get customersTitle => _('Customers', 'Customers');
  String get searchHint => _('Naam ya number dhoondein', 'Search name or number');
  String get balance => _('Baqaya', 'Balance');
  String get addCustomer => _('Naya customer', 'Add customer');
  String get noCustomers =>
      _('Abhi koi customer nahi. + dabayein.', 'No customers yet. Tap +.');

  // Customer detail / khata
  String get khata => _('Khata', 'Ledger');
  String get thisMonth => _('Is mahine', 'This month');
  String get payments => _('Payments', 'Payments');
  String get viewBill => _('Bill dekhein', 'View bill');
  String get addPayment => _('Payment lagayein', 'Add payment');
  String get edit => _('Edit', 'Edit');

  // Add / edit customer
  String get name => _('Naam', 'Name');
  String get phone => _('Phone', 'Phone');
  String get typeHouse => _('Ghar', 'House');
  String get typeShop => _('Dukan', 'Shop');
  String get addressNote => _('Pata / nishani', 'Address note');
  String get routePosition => _('Route number', 'Route position');
  String get unit => _('Unit', 'Unit');
  String get unitKg => _('Kg', 'Kg');
  String get unitL => _('Litre', 'Litre');
  String get morningQty => _('Subah ki miqdar', 'Morning quantity');
  String get eveningQty => _('Shaam ki miqdar', 'Evening quantity');
  String get rate => _('Rate', 'Rate');
  String get rateHint => _('Khali = default rate', 'Blank = default rate');
  String get openingBalance => _('Purana baqaya', 'Opening balance');
  String get save => _('Save', 'Save');
  String get cancel => _('Cancel', 'Cancel');
  String get requiredField => _('Zaroori hai', 'Required');

  // Reports / Hisaab
  String get hisaabTitle => _('Hisaab', 'Reports');
  String get todaySales => _('Aaj ki sale', "Today's sales");
  String get monthSales => _('Is mahine ki sale', "This month's sales");
  String get totalNaga => _('Total naga', 'Total naga');
  String get customerAway => _('Customer ne mana', 'Customer away');
  String get supplierMissed => _('Main nahi aaya', 'I missed');
  String get totalPayments => _('Total payments', 'Total payments');
  String get totalOutstanding => _('Total baqaya', 'Total outstanding');
  String get settings => _('Settings', 'Settings');

  // Monthly bill
  String get billTitle => _('Bill', 'Bill');
  String get daysSupplied => _('Din diye', 'Days supplied');
  String get regularMilk => _('Doodh', 'Milk');
  String get extraMilk => _('Extra', 'Extra');
  String get totalMilk => _('Total doodh', 'Total milk');
  String get milkCharges => _('Doodh ka bill', 'Milk charges');
  String get previousBalance => _('Pichhla baqaya', 'Previous balance');
  String get paidThisMonth => _('Is mahine jama', 'Paid this month');
  String get balanceDue => _('Baqaya', 'Balance due');
  String get nagaDates => _('Naga din', 'Naga dates');
  String get sendWhatsApp => _('WhatsApp par bhejo', 'Send on WhatsApp');
  String get shareImage => _('Image bhejo', 'Share image');

  // Khula sheet
  String get looseSale => _('Khula doodh', 'Loose sale');
  String get amountRs => _('Rupay', 'Amount (Rs)');
  String get walkIn => _('Walk-in (naam nahi)', 'Walk-in (no name)');
  String get optionalCustomer => _('Customer (optional)', 'Customer (optional)');

  // Naga reasons
  String get nagaReasonTitle => _('Naga kyun?', 'Why naga?');
  String get reasonCustomer =>
      _('Customer ne mana kiya', 'Customer refused / away');
  String get reasonSupplier => _('Main nahi aaya', 'I did not come');
  String get reasonOther => _('Other', 'Other');
  String get skipReason => _('Chhod dein', 'Skip');

  // Payment sheet
  String get paymentTitle => _('Payment', 'Payment');
  String get methodCash => _('Cash', 'Cash');
  String get methodJazzCash => _('JazzCash', 'JazzCash');
  String get methodEasypaisa => _('Easypaisa', 'Easypaisa');
  String get methodBank => _('Bank', 'Bank');

  // Extra sheet
  String get extraTitle => _('Extra miqdar', 'Extra quantity');
  String get extraHint =>
      _('Fixed order ke upar kitna extra', 'Extra on top of fixed order');

  // Common
  String get done => _('Theek hai', 'Done');
  String get yes => _('Haan', 'Yes');
  String get no => _('Nahi', 'No');
  String roundClosed(int n) =>
      _('$n customers save ho gaye', '$n customers saved');
}
