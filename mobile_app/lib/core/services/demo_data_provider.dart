import 'package:eventflow_app/features/authentication/data/models/user_model.dart';
import 'package:eventflow_app/features/dashboard/data/models/dashboard_model.dart';
import 'package:eventflow_app/features/bookings/data/models/booking_model.dart';
import 'package:eventflow_app/features/customers/data/models/customer_model.dart';
import 'package:eventflow_app/features/leads/data/models/lead_model.dart';
import 'package:eventflow_app/features/venues/data/models/venue_model.dart';
import 'package:eventflow_app/features/payments/data/models/payment_model.dart';
import 'package:eventflow_app/features/invoices/data/models/invoice_model.dart';
import 'package:eventflow_app/features/notifications/data/models/notification_model.dart';

class DemoDataProvider {
  static final DemoDataProvider _instance = DemoDataProvider._();
  factory DemoDataProvider() => _instance;
  DemoDataProvider._();

  UserModel get guestUser => UserModel(
        id: 0,
        fullName: 'Guest User',
        email: 'guest@eventflow.app',
        role: 'GUEST',
      );

  DashboardModel get dashboard => DashboardModel(
        totalRevenue: 1258000,
        totalBookings: 20,
        activeBookings: 8,
        totalCustomers: 40,
        totalLeads: 25,
        pendingPayments: 185000,
        occupancyRate: 68.5,
        recentBookings: recentBookingsDemo,
        upcomingEvents: upcomingEventsDemo,
        monthlyRevenue: monthlyRevenueDemo,
      );

  List<RecentBooking> get recentBookingsDemo => bookings.take(5).map((b) => RecentBooking(
        id: b.id,
        bookingNumber: b.bookingNumber,
        customerName: b.customerName,
        eventDate: b.eventDate,
        status: b.status,
        totalAmount: b.totalAmount,
      )).toList();

  List<UpcomingEvent> get upcomingEventsDemo => bookings.where((b) => b.status == 'CONFIRMED' || b.status == 'TENTATIVE').take(5).map((b) => UpcomingEvent(
        id: b.id,
        bookingNumber: b.bookingNumber,
        customerName: b.customerName,
        eventDate: b.eventDate,
        venueName: b.venueName,
      )).toList();

  List<MonthlyRevenue> get monthlyRevenueDemo => [
        MonthlyRevenue(month: 'Jan', amount: 85000),
        MonthlyRevenue(month: 'Feb', amount: 92000),
        MonthlyRevenue(month: 'Mar', amount: 78000),
        MonthlyRevenue(month: 'Apr', amount: 110000),
        MonthlyRevenue(month: 'May', amount: 95000),
        MonthlyRevenue(month: 'Jun', amount: 125000),
        MonthlyRevenue(month: 'Jul', amount: 142000),
        MonthlyRevenue(month: 'Aug', amount: 118000),
        MonthlyRevenue(month: 'Sep', amount: 105000),
        MonthlyRevenue(month: 'Oct', amount: 135000),
        MonthlyRevenue(month: 'Nov', amount: 98000),
        MonthlyRevenue(month: 'Dec', amount: 82000),
      ];

  final List<BookingModel> bookings = [
    BookingModel(id: 1, bookingNumber: 'BK-2024-001', venue: 1, venueName: 'Grand Palace Hall', customer: 1, customerName: 'Rajesh Sharma', package: 1, eventType: 'Wedding', eventDate: '2024-03-15', guestCount: 350, totalAmount: 850000, advanceAmount: 250000, status: 'CONFIRMED', remarks: 'Premium wedding package with full catering', createdAt: '2024-01-10'),
    BookingModel(id: 2, bookingNumber: 'BK-2024-002', venue: 2, venueName: 'Skyview Banquet', customer: 2, customerName: 'Priya Patel', package: 2, eventType: 'Birthday', eventDate: '2024-04-20', guestCount: 80, totalAmount: 125000, advanceAmount: 50000, status: 'CONFIRMED', remarks: 'Sweet sixteen celebration', createdAt: '2024-02-05'),
    BookingModel(id: 3, bookingNumber: 'BK-2024-003', venue: 3, venueName: 'Green Lawns Resort', customer: 3, customerName: 'Amit Verma', package: 1, eventType: 'Corporate', eventDate: '2024-05-10', guestCount: 200, totalAmount: 350000, advanceAmount: 100000, status: 'TENTATIVE', remarks: 'Annual sales conference', createdAt: '2024-03-01'),
    BookingModel(id: 4, bookingNumber: 'BK-2024-004', venue: 1, venueName: 'Grand Palace Hall', customer: 4, customerName: 'Sunita Gupta', package: 3, eventType: 'Wedding', eventDate: '2024-06-22', guestCount: 500, totalAmount: 1200000, advanceAmount: 400000, status: 'DRAFT', remarks: null, createdAt: '2024-03-15'),
    BookingModel(id: 5, bookingNumber: 'BK-2024-005', venue: 4, venueName: 'Rooftop Terrace', customer: 5, customerName: 'Vikram Singh', package: 2, eventType: 'Party', eventDate: '2024-04-05', guestCount: 60, totalAmount: 85000, advanceAmount: 25000, status: 'CONFIRMED', remarks: 'Birthday party for father', createdAt: '2024-02-20'),
    BookingModel(id: 6, bookingNumber: 'BK-2024-006', venue: 5, venueName: 'Crystal Convention', customer: 6, customerName: 'Neha Jain', package: 1, eventType: 'Conference', eventDate: '2024-07-18', guestCount: 300, totalAmount: 450000, advanceAmount: 150000, status: 'TENTATIVE', remarks: 'Tech summit 2024', createdAt: '2024-04-01'),
    BookingModel(id: 7, bookingNumber: 'BK-2024-007', venue: 2, venueName: 'Skyview Banquet', customer: 7, customerName: 'Deepak Kumar', package: 2, eventType: 'Wedding', eventDate: '2024-05-30', guestCount: 150, totalAmount: 450000, advanceAmount: 150000, status: 'CONFIRMED', remarks: 'Small family wedding', createdAt: '2024-03-10'),
    BookingModel(id: 8, bookingNumber: 'BK-2024-008', venue: 3, venueName: 'Green Lawns Resort', customer: 8, customerName: 'Anjali Desai', package: 1, eventType: 'Birthday', eventDate: '2024-04-12', guestCount: 100, totalAmount: 150000, advanceAmount: 50000, status: 'CONFIRMED', remarks: '50th birthday celebration', createdAt: '2024-02-28'),
    BookingModel(id: 9, bookingNumber: 'BK-2024-009', venue: 1, venueName: 'Grand Palace Hall', customer: 9, customerName: 'Rahul Mehta', package: 2, eventType: 'Corporate', eventDate: '2024-08-15', guestCount: 150, totalAmount: 280000, advanceAmount: 80000, status: 'TENTATIVE', remarks: 'Product launch event', createdAt: '2024-05-01'),
    BookingModel(id: 10, bookingNumber: 'BK-2024-010', venue: 4, venueName: 'Rooftop Terrace', customer: 10, customerName: 'Pooja Reddy', package: 3, eventType: 'Party', eventDate: '2024-06-01', guestCount: 40, totalAmount: 65000, advanceAmount: 20000, status: 'CONFIRMED', remarks: 'Kitty party', createdAt: '2024-04-15'),
    BookingModel(id: 11, bookingNumber: 'BK-2024-011', venue: 5, venueName: 'Crystal Convention', customer: 11, customerName: 'Suresh Iyer', package: 1, eventType: 'Wedding', eventDate: '2024-09-14', guestCount: 400, totalAmount: 950000, advanceAmount: 300000, status: 'DRAFT', remarks: null, createdAt: '2024-05-20'),
    BookingModel(id: 12, bookingNumber: 'BK-2024-012', venue: 2, venueName: 'Skyview Banquet', customer: 12, customerName: 'Kavita Nair', package: 2, eventType: 'Conference', eventDate: '2024-07-05', guestCount: 120, totalAmount: 200000, advanceAmount: 60000, status: 'CONFIRMED', remarks: 'Healthcare seminar', createdAt: '2024-04-20'),
    BookingModel(id: 13, bookingNumber: 'BK-2024-013', venue: 3, venueName: 'Green Lawns Resort', customer: 13, customerName: 'Arun Joshi', package: 1, eventType: 'Birthday', eventDate: '2024-08-25', guestCount: 90, totalAmount: 135000, advanceAmount: 40000, status: 'IN_PROGRESS', remarks: null, createdAt: '2024-06-01'),
    BookingModel(id: 14, bookingNumber: 'BK-2024-014', venue: 4, venueName: 'Rooftop Terrace', customer: 14, customerName: 'Meena Krishnan', package: 2, eventType: 'Party', eventDate: '2024-05-18', guestCount: 50, totalAmount: 75000, advanceAmount: 25000, status: 'COMPLETED', remarks: 'Anniversary party - completed successfully', createdAt: '2024-03-25'),
    BookingModel(id: 15, bookingNumber: 'BK-2024-015', venue: 1, venueName: 'Grand Palace Hall', customer: 15, customerName: 'Vivek Saxena', package: 3, eventType: 'Wedding', eventDate: '2024-10-12', guestCount: 600, totalAmount: 1500000, advanceAmount: 500000, status: 'TENTATIVE', remarks: 'Grand wedding with live band', createdAt: '2024-05-15'),
    BookingModel(id: 16, bookingNumber: 'BK-2024-016', venue: 5, venueName: 'Crystal Convention', customer: 16, customerName: 'Shweta Mishra', package: 1, eventType: 'Corporate', eventDate: '2024-09-30', guestCount: 250, totalAmount: 380000, advanceAmount: 100000, status: 'CONFIRMED', remarks: 'Quarterly business review', createdAt: '2024-06-10'),
    BookingModel(id: 17, bookingNumber: 'BK-2024-017', venue: 1, venueName: 'Grand Palace Hall', customer: 17, customerName: 'Ravi Agarwal', package: 2, eventType: 'Party', eventDate: '2024-11-08', guestCount: 70, totalAmount: 95000, advanceAmount: 30000, status: 'DRAFT', remarks: null, createdAt: '2024-06-20'),
    BookingModel(id: 18, bookingNumber: 'BK-2024-018', venue: 2, venueName: 'Skyview Banquet', customer: 18, customerName: 'Asha Rao', package: 1, eventType: 'Wedding', eventDate: '2024-11-25', guestCount: 200, totalAmount: 550000, advanceAmount: 200000, status: 'TENTATIVE', remarks: 'Day wedding with lunch', createdAt: '2024-06-25'),
    BookingModel(id: 19, bookingNumber: 'BK-2024-019', venue: 3, venueName: 'Green Lawns Resort', customer: 19, customerName: 'Nitin Kapoor', package: 2, eventType: 'Conference', eventDate: '2024-10-05', guestCount: 180, totalAmount: 310000, advanceAmount: 100000, status: 'CONFIRMED', remarks: 'Leadership summit', createdAt: '2024-06-05'),
    BookingModel(id: 20, bookingNumber: 'BK-2024-020', venue: 4, venueName: 'Rooftop Terrace', customer: 20, customerName: 'Lata Menon', package: 3, eventType: 'Birthday', eventDate: '2024-07-12', guestCount: 30, totalAmount: 55000, advanceAmount: 15000, status: 'CANCELLED', remarks: 'Cancelled due to date conflict', createdAt: '2024-05-10'),
  ];

  final List<CustomerModel> customers = [
    CustomerModel(id: 1, fullName: 'Rajesh Sharma', mobile: '9876543210', email: 'rajesh.sharma@gmail.com', address: '42, Lokhandwala Complex, Andheri West, Mumbai', remarks: 'Regular customer, prefers premium packages', createdAt: '2023-11-15'),
    CustomerModel(id: 2, fullName: 'Priya Patel', mobile: '9876543211', email: 'priya.patel@yahoo.com', address: '15, Satellite Road, Ahmedabad', remarks: null, createdAt: '2023-12-01'),
    CustomerModel(id: 3, fullName: 'Amit Verma', mobile: '9876543212', email: 'amit.verma@techcorp.in', address: '88, Electronic City Phase 1, Bangalore', remarks: 'Corporate client - TechCorp India', createdAt: '2024-01-05'),
    CustomerModel(id: 4, fullName: 'Sunita Gupta', mobile: '9876543213', email: 'sunita.gupta@gmail.com', address: '7, Model Town, Delhi', remarks: null, createdAt: '2023-11-20'),
    CustomerModel(id: 5, fullName: 'Vikram Singh', mobile: '9876543214', email: 'vikram.singh@rediffmail.com', address: '23, Posh Colony, Jaipur', remarks: 'VIP client, personal referral', createdAt: '2024-01-10'),
    CustomerModel(id: 6, fullName: 'Neha Jain', mobile: '9876543215', email: 'neha.jain@outlook.com', address: '56, MG Road, Pune', remarks: null, createdAt: '2024-02-01'),
    CustomerModel(id: 7, fullName: 'Deepak Kumar', mobile: '9876543216', email: 'deepak.k@gmail.com', address: '12, Boring Road, Patna', remarks: 'Budget conscious', createdAt: '2024-02-15'),
    CustomerModel(id: 8, fullName: 'Anjali Desai', mobile: '9876543217', email: 'anjali.desai@hotmail.com', address: '34, FC Road, Pune', remarks: null, createdAt: '2023-12-20'),
    CustomerModel(id: 9, fullName: 'Rahul Mehta', mobile: '9876543218', email: 'rahul.mehta@gmail.com', address: '67, Linking Road, Bandra West, Mumbai', remarks: 'Prefers weekend events', createdAt: '2024-03-01'),
    CustomerModel(id: 10, fullName: 'Pooja Reddy', mobile: '9876543219', email: 'pooja.reddy@gmail.com', address: '89, Jubilee Hills, Hyderabad', remarks: null, createdAt: '2024-01-25'),
    CustomerModel(id: 11, fullName: 'Suresh Iyer', mobile: '9876543220', email: 'suresh.iyer@gmail.com', address: '45, Mylapore, Chennai', remarks: 'Large family wedding', createdAt: '2024-03-10'),
    CustomerModel(id: 12, fullName: 'Kavita Nair', mobile: '9876543221', email: 'kavita.nair@gmail.com', address: '78, Koramangala, Bangalore', remarks: null, createdAt: '2024-02-20'),
    CustomerModel(id: 13, fullName: 'Arun Joshi', mobile: '9876543222', email: 'arun.joshi@gmail.com', address: '21, Gomti Nagar, Lucknow', remarks: null, createdAt: '2024-03-15'),
    CustomerModel(id: 14, fullName: 'Meena Krishnan', mobile: '9876543223', email: 'meena.krishnan@gmail.com', address: '55, Teynampet, Chennai', remarks: 'Anniversary celebration', createdAt: '2023-12-05'),
    CustomerModel(id: 15, fullName: 'Vivek Saxena', mobile: '9876543224', email: 'vivek.saxena@gmail.com', address: '9, Civil Lines, Kanpur', remarks: 'High budget wedding', createdAt: '2024-04-01'),
    CustomerModel(id: 16, fullName: 'Shweta Mishra', mobile: '9876543225', email: 'shweta.m@company.com', address: '33, HSR Layout, Bangalore', remarks: 'Corporate - TechMahindra', createdAt: '2024-03-20'),
    CustomerModel(id: 17, fullName: 'Ravi Agarwal', mobile: '9876543226', email: 'ravi.agarwal@gmail.com', address: '11, Greater Kailash, Delhi', remarks: null, createdAt: '2024-04-05'),
    CustomerModel(id: 18, fullName: 'Asha Rao', mobile: '9876543227', email: 'asha.rao@gmail.com', address: '66, Indiranagar, Bangalore', remarks: null, createdAt: '2024-04-10'),
    CustomerModel(id: 19, fullName: 'Nitin Kapoor', mobile: '9876543228', email: 'nitin.kapoor@fintech.in', address: '90, Bandra Kurla Complex, Mumbai', remarks: 'Corporate - FinTech Ltd', createdAt: '2024-03-05'),
    CustomerModel(id: 20, fullName: 'Lata Menon', mobile: '9876543229', email: 'lata.menon@gmail.com', address: '44, Panampilly Nagar, Kochi', remarks: null, createdAt: '2024-02-10'),
    CustomerModel(id: 21, fullName: 'Gaurav Bhatia', mobile: '9876543230', email: 'gaurav.b@gmail.com', address: '77, Sector 18, Noida', remarks: null, createdAt: '2024-04-15'),
    CustomerModel(id: 22, fullName: 'Ritu Kulkarni', mobile: '9876543231', email: 'ritu.kulkarni@gmail.com', address: '29, Wakad, Pune', remarks: null, createdAt: '2024-01-30'),
    CustomerModel(id: 23, fullName: 'Manoj Tiwari', mobile: '9876543232', email: 'manoj.tiwari@gmail.com', address: '5, Sigra, Varanasi', remarks: null, createdAt: '2024-04-20'),
    CustomerModel(id: 24, fullName: 'Sneha Choudhury', mobile: '9876543233', email: 'sneha.c@gmail.com', address: '38, Salt Lake, Kolkata', remarks: null, createdAt: '2024-03-25'),
    CustomerModel(id: 25, fullName: 'Vijay Pandey', mobile: '9876543234', email: 'vijay.pandey@gmail.com', address: '16, Aliganj, Lucknow', remarks: null, createdAt: '2024-02-25'),
    CustomerModel(id: 26, fullName: 'Aditi Thakur', mobile: '9876543235', email: 'aditi.thakur@gmail.com', address: '92, Powai, Mumbai', remarks: 'Referral from Rajesh Sharma', createdAt: '2024-05-01'),
    CustomerModel(id: 27, fullName: 'Rohit Malhotra', mobile: '9876543236', email: 'rohit.m@yahoo.com', address: '58, Civil Lines, Delhi', remarks: null, createdAt: '2024-04-25'),
    CustomerModel(id: 28, fullName: 'Tara Shetty', mobile: '9876543237', email: 'tara.shetty@gmail.com', address: '72, Mangalore', remarks: null, createdAt: '2024-03-30'),
    CustomerModel(id: 29, fullName: 'Karan Wagh', mobile: '9876543238', email: 'karan.wagh@gmail.com', address: '25, Hinjewadi, Pune', remarks: null, createdAt: '2024-05-05'),
    CustomerModel(id: 30, fullName: 'Nandini Chopra', mobile: '9876543239', email: 'nandini.c@gmail.com', address: '61, Defence Colony, Delhi', remarks: null, createdAt: '2024-04-30'),
    CustomerModel(id: 31, fullName: 'Prakash Rao', mobile: '9876543240', email: 'prakash.rao@gmail.com', address: '83, Jayanagar, Bangalore', remarks: null, createdAt: '2024-05-10'),
    CustomerModel(id: 32, fullName: 'Divya Saxena', mobile: '9876543241', email: 'divya.s@gmail.com', address: '39, Dehradun', remarks: null, createdAt: '2024-05-15'),
    CustomerModel(id: 33, fullName: 'Akshay Bhandari', mobile: '9876543242', email: 'akshay.b@gmail.com', address: '47, Rajouri Garden, Delhi', remarks: null, createdAt: '2024-05-20'),
    CustomerModel(id: 34, fullName: 'Kiran Bedi', mobile: '9876543243', email: 'kiran.bedi@gmail.com', address: '14, Aundh, Pune', remarks: null, createdAt: '2024-06-01'),
    CustomerModel(id: 35, fullName: 'Mohan Das', mobile: '9876543244', email: 'mohan.das@gmail.com', address: '31, Ernakulam, Kochi', remarks: null, createdAt: '2024-05-25'),
    CustomerModel(id: 36, fullName: 'Swati Ghosh', mobile: '9876543245', email: 'swati.ghosh@gmail.com', address: '53, Dum Dum, Kolkata', remarks: null, createdAt: '2024-06-05'),
    CustomerModel(id: 37, fullName: 'Imran Khan', mobile: '9876543246', email: 'imran.khan@gmail.com', address: '8, Malad West, Mumbai', remarks: null, createdAt: '2024-06-10'),
    CustomerModel(id: 38, fullName: 'Zara Sheikh', mobile: '9876543247', email: 'zara.sheikh@gmail.com', address: '22, Bhopal', remarks: null, createdAt: '2024-06-15'),
    CustomerModel(id: 39, fullName: 'Harsh Vardhan', mobile: '9876543248', email: 'harsh.v@gmail.com', address: '96, Dwarka, Delhi', remarks: null, createdAt: '2024-06-20'),
    CustomerModel(id: 40, fullName: 'Geeta Nair', mobile: '9876543249', email: 'geeta.nair@gmail.com', address: '74, Thiruvananthapuram', remarks: null, createdAt: '2024-06-25'),
  ];

  final List<LeadModel> leads = [
    LeadModel(id: 1, customer: 21, customerName: 'Gaurav Bhatia', leadSource: 'Website', eventType: 'Wedding', expectedEventDate: '2025-01-15', expectedGuestCount: 300, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-01'),
    LeadModel(id: 2, customer: 22, customerName: 'Ritu Kulkarni', leadSource: 'Referral', eventType: 'Birthday', expectedEventDate: '2024-12-20', expectedGuestCount: 60, leadStatus: 'CONTACTED', assignedTo: 1, createdAt: '2024-05-28'),
    LeadModel(id: 3, customer: 23, customerName: 'Manoj Tiwari', leadSource: 'Social Media', eventType: 'Corporate', expectedEventDate: '2025-02-10', expectedGuestCount: 150, leadStatus: 'SITE_VISIT', assignedTo: 1, createdAt: '2024-05-15'),
    LeadModel(id: 4, customer: 24, customerName: 'Sneha Choudhury', leadSource: 'Phone', eventType: 'Conference', expectedEventDate: '2024-11-05', expectedGuestCount: 200, leadStatus: 'NEGOTIATION', assignedTo: 1, createdAt: '2024-04-20'),
    LeadModel(id: 5, customer: 25, customerName: 'Vijay Pandey', leadSource: 'Walk-in', eventType: 'Wedding', expectedEventDate: '2025-03-20', expectedGuestCount: 400, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-10'),
    LeadModel(id: 6, customer: 26, customerName: 'Aditi Thakur', leadSource: 'Referral', eventType: 'Party', expectedEventDate: '2024-10-12', expectedGuestCount: 80, leadStatus: 'CONTACTED', assignedTo: 2, createdAt: '2024-05-20'),
    LeadModel(id: 7, customer: 27, customerName: 'Rohit Malhotra', leadSource: 'Email', eventType: 'Corporate', expectedEventDate: '2025-01-25', expectedGuestCount: 120, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-05'),
    LeadModel(id: 8, customer: 28, customerName: 'Tara Shetty', leadSource: 'Website', eventType: 'Wedding', expectedEventDate: '2024-12-05', expectedGuestCount: 250, leadStatus: 'SITE_VISIT', assignedTo: 2, createdAt: '2024-05-10'),
    LeadModel(id: 9, customer: 29, customerName: 'Karan Wagh', leadSource: 'Social Media', eventType: 'Birthday', expectedEventDate: '2024-11-20', expectedGuestCount: 50, leadStatus: 'NEGOTIATION', assignedTo: 1, createdAt: '2024-04-25'),
    LeadModel(id: 10, customer: 30, customerName: 'Nandini Chopra', leadSource: 'Referral', eventType: 'Wedding', expectedEventDate: '2025-02-14', expectedGuestCount: 350, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-12'),
    LeadModel(id: 11, customer: 31, customerName: 'Prakash Rao', leadSource: 'Phone', eventType: 'Conference', expectedEventDate: '2024-09-15', expectedGuestCount: 180, leadStatus: 'CONVERTED', assignedTo: 1, createdAt: '2024-03-10'),
    LeadModel(id: 12, customer: 32, customerName: 'Divya Saxena', leadSource: 'Walk-in', eventType: 'Party', expectedEventDate: '2024-08-30', expectedGuestCount: 40, leadStatus: 'LOST', assignedTo: 2, createdAt: '2024-03-20'),
    LeadModel(id: 13, customer: 33, customerName: 'Akshay Bhandari', leadSource: 'Website', eventType: 'Corporate', expectedEventDate: '2025-04-10', expectedGuestCount: 200, leadStatus: 'CONTACTED', assignedTo: 1, createdAt: '2024-06-15'),
    LeadModel(id: 14, customer: 34, customerName: 'Kiran Bedi', leadSource: 'Social Media', eventType: 'Wedding', expectedEventDate: '2025-01-30', expectedGuestCount: 280, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-18'),
    LeadModel(id: 15, customer: 35, customerName: 'Mohan Das', leadSource: 'Referral', eventType: 'Birthday', expectedEventDate: '2024-12-10', expectedGuestCount: 70, leadStatus: 'SITE_VISIT', assignedTo: 2, createdAt: '2024-05-25'),
    LeadModel(id: 16, customer: 36, customerName: 'Swati Ghosh', leadSource: 'Email', eventType: 'Conference', expectedEventDate: '2025-03-05', expectedGuestCount: 250, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-20'),
    LeadModel(id: 17, customer: 37, customerName: 'Imran Khan', leadSource: 'Phone', eventType: 'Party', expectedEventDate: '2024-11-30', expectedGuestCount: 60, leadStatus: 'CONTACTED', assignedTo: 1, createdAt: '2024-06-08'),
    LeadModel(id: 18, customer: 38, customerName: 'Zara Sheikh', leadSource: 'Walk-in', eventType: 'Wedding', expectedEventDate: '2025-04-25', expectedGuestCount: 500, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-22'),
    LeadModel(id: 19, customer: 39, customerName: 'Harsh Vardhan', leadSource: 'Website', eventType: 'Corporate', expectedEventDate: '2025-02-20', expectedGuestCount: 100, leadStatus: 'NEGOTIATION', assignedTo: 2, createdAt: '2024-05-05'),
    LeadModel(id: 20, customer: 40, customerName: 'Geeta Nair', leadSource: 'Referral', eventType: 'Wedding', expectedEventDate: '2024-10-28', expectedGuestCount: 200, leadStatus: 'SITE_VISIT', assignedTo: 1, createdAt: '2024-04-15'),
    LeadModel(id: 21, customer: 1, customerName: 'Rajesh Sharma', leadSource: 'Phone', eventType: 'Conference', expectedEventDate: '2025-05-10', expectedGuestCount: 300, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-25'),
    LeadModel(id: 22, customer: 6, customerName: 'Neha Jain', leadSource: 'Referral', eventType: 'Birthday', expectedEventDate: '2025-01-05', expectedGuestCount: 90, leadStatus: 'CONTACTED', assignedTo: 2, createdAt: '2024-06-14'),
    LeadModel(id: 23, customer: 9, customerName: 'Rahul Mehta', leadSource: 'Social Media', eventType: 'Wedding', expectedEventDate: '2025-06-15', expectedGuestCount: 350, leadStatus: 'NEW', assignedTo: null, createdAt: '2024-06-28'),
    LeadModel(id: 24, customer: 15, customerName: 'Vivek Saxena', leadSource: 'Email', eventType: 'Corporate', expectedEventDate: '2025-03-30', expectedGuestCount: 160, leadStatus: 'NEGOTIATION', assignedTo: 1, createdAt: '2024-06-02'),
    LeadModel(id: 25, customer: 19, customerName: 'Nitin Kapoor', leadSource: 'Walk-in', eventType: 'Party', expectedEventDate: '2024-12-15', expectedGuestCount: 100, leadStatus: 'LOST', assignedTo: 2, createdAt: '2024-05-18'),
  ];

  final List<VenueModel> venues = [
    VenueModel(id: 1, name: 'Grand Palace Hall', venueType: 'Banquet Hall', capacity: 600, description: 'A majestic banquet hall with royal decor, chandeliers and a sprawling dance floor. Perfect for large weddings and corporate galas.', address: '101, Palace Road, Mumbai', latitude: 19.0760, longitude: 72.8777, weekdayPrice: 150000, weekendPrice: 200000, peakPrice: 300000, status: 'ACTIVE', createdAt: '2023-01-15'),
    VenueModel(id: 2, name: 'Skyview Banquet', venueType: 'Banquet Hall', capacity: 200, description: 'Modern banquet hall on the 15th floor with panoramic city views. Equipped with state-of-the-art sound and lighting.', address: '45, MG Road, Pune', latitude: 18.5204, longitude: 73.8567, weekdayPrice: 75000, weekendPrice: 100000, peakPrice: 150000, status: 'ACTIVE', createdAt: '2023-03-10'),
    VenueModel(id: 3, name: 'Green Lawns Resort', venueType: 'Lawn', capacity: 500, description: 'Sprawling 5-acre lawn with garden seating, a poolside area and natural greenery. Ideal for daytime events and outdoor weddings.', address: '88, NH-8, Jaipur Highway', latitude: 26.9124, longitude: 75.7873, weekdayPrice: 120000, weekendPrice: 160000, peakPrice: 250000, status: 'ACTIVE', createdAt: '2023-05-20'),
    VenueModel(id: 4, name: 'Rooftop Terrace', venueType: 'Rooftop', capacity: 80, description: 'Intimate rooftop venue with open-air seating and fairy lights. Great for small parties, birthdays and cocktail evenings.', address: '12, Cunningham Road, Bangalore', latitude: 12.9716, longitude: 77.5946, weekdayPrice: 40000, weekendPrice: 55000, peakPrice: 80000, status: 'ACTIVE', createdAt: '2023-06-01'),
    VenueModel(id: 5, name: 'Crystal Convention', venueType: 'Convention Center', capacity: 800, description: 'Large convention center with modular halls, VIP lounges and in-house catering. Built for conferences, exhibitions and large gatherings.', address: '67, Anna Salai, Chennai', latitude: 13.0827, longitude: 80.2707, weekdayPrice: 200000, weekendPrice: 280000, peakPrice: 400000, status: 'ACTIVE', createdAt: '2023-02-28'),
  ];

  final List<PaymentModel> payments = [
    PaymentModel(id: 1, booking: 1, bookingNumber: 'BK-2024-001', amount: 250000, paymentMethod: 'BANK_TRANSFER', paymentType: 'ADVANCE', transactionReference: 'NEFT-2024-00123', paymentDate: '2024-01-15', notes: 'Advance payment for wedding booking', createdAt: '2024-01-15'),
    PaymentModel(id: 2, booking: 1, bookingNumber: 'BK-2024-001', amount: 600000, paymentMethod: 'CHEQUE', paymentType: 'FINAL', transactionReference: 'CHQ-004578', paymentDate: '2024-03-10', notes: 'Balance payment', createdAt: '2024-03-10'),
    PaymentModel(id: 3, booking: 2, bookingNumber: 'BK-2024-002', amount: 50000, paymentMethod: 'CASH', paymentType: 'ADVANCE', transactionReference: null, paymentDate: '2024-02-10', notes: 'Cash advance', createdAt: '2024-02-10'),
    PaymentModel(id: 4, booking: 5, bookingNumber: 'BK-2024-005', amount: 25000, paymentMethod: 'UPI', paymentType: 'ADVANCE', transactionReference: 'upi@paytm-987654', paymentDate: '2024-02-25', notes: 'UPI payment', createdAt: '2024-02-25'),
    PaymentModel(id: 5, booking: 7, bookingNumber: 'BK-2024-007', amount: 150000, paymentMethod: 'BANK_TRANSFER', paymentType: 'ADVANCE', transactionReference: 'RTGS-2024-00456', paymentDate: '2024-03-15', notes: null, createdAt: '2024-03-15'),
    PaymentModel(id: 6, booking: 8, bookingNumber: 'BK-2024-008', amount: 50000, paymentMethod: 'CASH', paymentType: 'ADVANCE', transactionReference: null, paymentDate: '2024-03-01', notes: null, createdAt: '2024-03-01'),
    PaymentModel(id: 7, booking: 10, bookingNumber: 'BK-2024-010', amount: 20000, paymentMethod: 'UPI', paymentType: 'ADVANCE', transactionReference: 'gpay-123456', paymentDate: '2024-04-18', notes: 'Google Pay', createdAt: '2024-04-18'),
    PaymentModel(id: 8, booking: 2, bookingNumber: 'BK-2024-002', amount: 75000, paymentMethod: 'CARD', paymentType: 'FINAL', transactionReference: 'CARD-XXXX-4521', paymentDate: '2024-04-15', notes: 'Credit card payment at venue', createdAt: '2024-04-15'),
    PaymentModel(id: 9, booking: 5, bookingNumber: 'BK-2024-005', amount: 60000, paymentMethod: 'CASH', paymentType: 'FINAL', transactionReference: null, paymentDate: '2024-04-05', notes: 'Balance paid at event', createdAt: '2024-04-05'),
    PaymentModel(id: 10, booking: 12, bookingNumber: 'BK-2024-012', amount: 60000, paymentMethod: 'BANK_TRANSFER', paymentType: 'ADVANCE', transactionReference: 'NEFT-2024-00789', paymentDate: '2024-04-25', notes: null, createdAt: '2024-04-25'),
    PaymentModel(id: 11, booking: 14, bookingNumber: 'BK-2024-014', amount: 25000, paymentMethod: 'CASH', paymentType: 'ADVANCE', transactionReference: null, paymentDate: '2024-04-01', notes: 'Cash at booking', createdAt: '2024-04-01'),
    PaymentModel(id: 12, booking: 14, bookingNumber: 'BK-2024-014', amount: 50000, paymentMethod: 'UPI', paymentType: 'FINAL', transactionReference: 'phonepe-789012', paymentDate: '2024-05-18', notes: 'PhonePe payment', createdAt: '2024-05-18'),
    PaymentModel(id: 13, booking: 16, bookingNumber: 'BK-2024-016', amount: 100000, paymentMethod: 'BANK_TRANSFER', paymentType: 'ADVANCE', transactionReference: 'RTGS-2024-00987', paymentDate: '2024-06-12', notes: 'Corporate booking advance', createdAt: '2024-06-12'),
    PaymentModel(id: 14, booking: 3, bookingNumber: 'BK-2024-003', amount: 100000, paymentMethod: 'CHEQUE', paymentType: 'ADVANCE', transactionReference: 'CHQ-005612', paymentDate: '2024-03-05', notes: null, createdAt: '2024-03-05'),
    PaymentModel(id: 15, booking: 19, bookingNumber: 'BK-2024-019', amount: 100000, paymentMethod: 'BANK_TRANSFER', paymentType: 'ADVANCE', transactionReference: 'NEFT-2024-01123', paymentDate: '2024-06-08', notes: null, createdAt: '2024-06-08'),
  ];

  final List<InvoiceModel> invoices = [
    InvoiceModel(id: 1, booking: 1, invoiceNumber: 'INV-2024-001', invoiceDate: '2024-03-15', subtotal: 714286, taxAmount: 135714, totalAmount: 850000, pdfFile: null, createdAt: '2024-03-15'),
    InvoiceModel(id: 2, booking: 2, invoiceNumber: 'INV-2024-002', invoiceDate: '2024-04-20', subtotal: 105042, taxAmount: 19958, totalAmount: 125000, pdfFile: null, createdAt: '2024-04-20'),
    InvoiceModel(id: 3, booking: 5, invoiceNumber: 'INV-2024-003', invoiceDate: '2024-04-05', subtotal: 71429, taxAmount: 13571, totalAmount: 85000, pdfFile: null, createdAt: '2024-04-05'),
    InvoiceModel(id: 4, booking: 7, invoiceNumber: 'INV-2024-004', invoiceDate: '2024-05-30', subtotal: 378151, taxAmount: 71849, totalAmount: 450000, pdfFile: null, createdAt: '2024-05-30'),
    InvoiceModel(id: 5, booking: 8, invoiceNumber: 'INV-2024-005', invoiceDate: '2024-04-12', subtotal: 126050, taxAmount: 23950, totalAmount: 150000, pdfFile: null, createdAt: '2024-04-12'),
    InvoiceModel(id: 6, booking: 10, invoiceNumber: 'INV-2024-006', invoiceDate: '2024-06-01', subtotal: 54622, taxAmount: 10378, totalAmount: 65000, pdfFile: null, createdAt: '2024-06-01'),
    InvoiceModel(id: 7, booking: 12, invoiceNumber: 'INV-2024-007', invoiceDate: '2024-07-05', subtotal: 168067, taxAmount: 31933, totalAmount: 200000, pdfFile: null, createdAt: '2024-07-05'),
    InvoiceModel(id: 8, booking: 14, invoiceNumber: 'INV-2024-008', invoiceDate: '2024-05-18', subtotal: 63025, taxAmount: 11975, totalAmount: 75000, pdfFile: null, createdAt: '2024-05-18'),
    InvoiceModel(id: 9, booking: 16, invoiceNumber: 'INV-2024-009', invoiceDate: '2024-09-30', subtotal: 319328, taxAmount: 60672, totalAmount: 380000, pdfFile: null, createdAt: '2024-09-30'),
    InvoiceModel(id: 10, booking: 1, invoiceNumber: 'INV-2024-010', invoiceDate: '2024-03-15', subtotal: 714286, taxAmount: 135714, totalAmount: 850000, pdfFile: null, createdAt: '2024-03-15'),
    InvoiceModel(id: 11, booking: 3, invoiceNumber: 'INV-2024-011', invoiceDate: '2024-05-10', subtotal: 294118, taxAmount: 55882, totalAmount: 350000, pdfFile: null, createdAt: '2024-05-10'),
    InvoiceModel(id: 12, booking: 6, invoiceNumber: 'INV-2024-012', invoiceDate: '2024-07-18', subtotal: 378151, taxAmount: 71849, totalAmount: 450000, pdfFile: null, createdAt: '2024-07-18'),
    InvoiceModel(id: 13, booking: 9, invoiceNumber: 'INV-2024-013', invoiceDate: '2024-08-15', subtotal: 235294, taxAmount: 44706, totalAmount: 280000, pdfFile: null, createdAt: '2024-08-15'),
    InvoiceModel(id: 14, booking: 13, invoiceNumber: 'INV-2024-014', invoiceDate: '2024-08-25', subtotal: 113445, taxAmount: 21555, totalAmount: 135000, pdfFile: null, createdAt: '2024-08-25'),
    InvoiceModel(id: 15, booking: 19, invoiceNumber: 'INV-2024-015', invoiceDate: '2024-10-05', subtotal: 260504, taxAmount: 49496, totalAmount: 310000, pdfFile: null, createdAt: '2024-10-05'),
  ];

  final List<NotificationModel> notifications = [
    NotificationModel(id: 1, title: 'Booking Confirmed', message: 'Booking BK-2024-001 for Rajesh Sharma has been confirmed.', channel: 'SYSTEM', status: 'READ', createdAt: '2024-01-12 10:30 AM'),
    NotificationModel(id: 2, title: 'Payment Received', message: 'Payment of ₹2,50,000 received for booking BK-2024-001.', channel: 'SYSTEM', status: 'READ', createdAt: '2024-01-15 02:15 PM'),
    NotificationModel(id: 3, title: 'New Lead Assigned', message: 'New lead from Gaurav Bhatia assigned to you.', channel: 'SYSTEM', status: 'READ', createdAt: '2024-06-01 09:00 AM'),
    NotificationModel(id: 4, title: 'Upcoming Event Reminder', message: 'Event BK-2024-005 (Vikram Singh) is scheduled for tomorrow.', channel: 'REMINDER', status: 'READ', createdAt: '2024-04-04 08:00 AM'),
    NotificationModel(id: 5, title: 'Booking Cancelled', message: 'Booking BK-2024-020 for Lata Menon has been cancelled.', channel: 'SYSTEM', status: 'READ', createdAt: '2024-05-12 11:45 AM'),
    NotificationModel(id: 6, title: 'Payment Overdue', message: 'Balance payment of ₹60,000 for booking BK-2024-005 is overdue.', channel: 'ALERT', status: 'UNREAD', createdAt: '2024-04-10 09:30 AM'),
    NotificationModel(id: 7, title: 'Site Visit Scheduled', message: 'Site visit for lead #3 (Manoj Tiwari) is scheduled for tomorrow.', channel: 'REMINDER', status: 'UNREAD', createdAt: '2024-06-20 03:00 PM'),
    NotificationModel(id: 8, title: 'Invoice Generated', message: 'Invoice INV-2024-009 for Shweta Mishra has been generated.', channel: 'SYSTEM', status: 'UNREAD', createdAt: '2024-09-30 04:20 PM'),
    NotificationModel(id: 9, title: 'Customer Feedback', message: 'Meena Krishnan has left a 5-star review for her event.', channel: 'SYSTEM', status: 'UNREAD', createdAt: '2024-05-20 06:00 PM'),
    NotificationModel(id: 10, title: 'Welcome to EventFlow', message: 'Thank you for exploring EventFlow in demo mode!', channel: 'SYSTEM', status: 'UNREAD', createdAt: '2024-06-26 12:00 PM'),
  ];

  List<BookingModel> searchBookings(String? query, String? status) {
    var result = bookings;
    if (query != null && query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((b) =>
        b.customerName.toLowerCase().contains(q) ||
        b.bookingNumber.toLowerCase().contains(q) ||
        b.eventType.toLowerCase().contains(q)
      ).toList();
    }
    if (status != null) {
      result = result.where((b) => b.status == status).toList();
    }
    return result;
  }

  List<CustomerModel> searchCustomers(String? query) {
    if (query == null || query.isEmpty) return customers;
    final q = query.toLowerCase();
    return customers.where((c) =>
      c.fullName.toLowerCase().contains(q) ||
      c.mobile.contains(q) ||
      (c.email?.toLowerCase().contains(q) ?? false)
    ).toList();
  }

  List<LeadModel> searchLeads(String? query) {
    if (query == null || query.isEmpty) return leads;
    final q = query.toLowerCase();
    return leads.where((l) =>
      l.customerName.toLowerCase().contains(q) ||
      (l.leadSource?.toLowerCase().contains(q) ?? false) ||
      (l.eventType?.toLowerCase().contains(q) ?? false)
    ).toList();
  }
}
