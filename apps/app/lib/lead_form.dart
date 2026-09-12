import 'package:flutter/material.dart';

/// The lead wizard is spec-driven: one const list describes every step and
/// field, and `add_farmer.dart` renders it. Adding a field is a one-line edit.

class FieldSpec {
  const FieldSpec(this.id, this.label, {this.icon, this.options, this.required = false, this.keyboard, this.lines = 1});
  final String id;
  final String label;
  final IconData? icon;

  /// Non-null turns the field into a dropdown.
  final List<String>? options;
  final bool required;
  final TextInputType? keyboard;
  final int lines;
}

class StepSpec {
  const StepSpec(this.title, this.subtitle, this.icon, this.fields);
  final String title;
  final String subtitle;
  final IconData icon;
  final List<FieldSpec> fields;
}

const _phone = TextInputType.phone;
const _number = TextInputType.number;

const leadSteps = <StepSpec>[
  StepSpec('Basic Information', 'Farmer personal details', Icons.person_outline_rounded, [
    FieldSpec('name', 'Farmer Name', icon: Icons.person_outline_rounded, required: true),
    FieldSpec('fatherName', 'S / O · W / O', icon: Icons.people_outline_rounded, required: true),
    FieldSpec('mobile', 'Mobile Number', icon: Icons.phone_outlined, required: true, keyboard: _phone),
    FieldSpec('altMobile', 'Alternate Number', icon: Icons.phone_android_outlined, keyboard: _phone),
    FieldSpec('aadhaar', 'Aadhaar Number', icon: Icons.badge_outlined, keyboard: _number),
    FieldSpec('address', 'Address', icon: Icons.location_on_outlined, lines: 2),
    FieldSpec('gender', 'Gender', icon: Icons.wc_outlined, options: ['Male', 'Female', 'Other']),
    FieldSpec('dob', 'Date of Birth', icon: Icons.cake_outlined),
    FieldSpec('community', 'Community', icon: Icons.groups_outlined, options: ['General', 'SC', 'ST', 'MBC', 'BC']),
  ]),
  StepSpec('Land Information', 'Patta and land details', Icons.terrain_outlined, [
    FieldSpec('state', 'State', icon: Icons.public_outlined, options: ['Tamil Nadu', 'Kerala', 'Karnataka', 'Andhra Pradesh']),
    FieldSpec('district', 'District', icon: Icons.location_city_outlined, required: true),
    FieldSpec('taluk', 'Taluk / Block', icon: Icons.account_balance_outlined, required: true),
    FieldSpec('village', 'Village', icon: Icons.holiday_village_outlined, required: true),
    FieldSpec('pattaNumber', 'Patta Number', icon: Icons.tag_rounded),
    FieldSpec('surveyNumbers', 'Survey Number(s)', icon: Icons.map_outlined),
    FieldSpec('landExtent', 'Total Land Extent', icon: Icons.straighten_rounded, keyboard: _number),
    FieldSpec('landUnit', 'Unit', icon: Icons.square_foot_outlined, options: ['Acres', 'Hectares', 'Cents']),
    FieldSpec('landOwnership', 'Type of Land', icon: Icons.assignment_outlined, options: ['Own', 'Lease', 'Joint']),
  ]),
  StepSpec('Product Information', 'Select product and scheme', Icons.agriculture_outlined, [
    FieldSpec('productCategory', 'Product Category', icon: Icons.category_outlined, options: ['Agri Equipment', 'Tractor', 'Irrigation', 'Seeds & Inputs']),
    FieldSpec('productName', 'Product Name', icon: Icons.inventory_2_outlined, required: true),
    FieldSpec('brand', 'Brand', icon: Icons.sell_outlined),
    FieldSpec('model', 'Model', icon: Icons.precision_manufacturing_outlined),
    FieldSpec('price', 'Price (Rs)', icon: Icons.currency_rupee_rounded, keyboard: _number),
    FieldSpec('scheme', 'Scheme Category', icon: Icons.verified_outlined, options: ['Subsidy', 'Non-Subsidy']),
    FieldSpec('subsidyPercent', 'Subsidy Percentage', icon: Icons.percent_rounded, options: ['25%', '35%', '50%', '75%']),
    FieldSpec('farmerContribution', 'Farmer Contribution (Rs)', icon: Icons.savings_outlined, keyboard: _number),
  ]),
  StepSpec('Delivery Information', 'Order and delivery details', Icons.local_shipping_outlined, [
    FieldSpec('orderNumber', 'Order Number', icon: Icons.receipt_long_outlined),
    FieldSpec('orderDate', 'Order Date', icon: Icons.event_outlined),
    FieldSpec('quantity', 'Quantity', icon: Icons.numbers_rounded, keyboard: _number),
    FieldSpec('deliveryDate', 'Delivery Date', icon: Icons.event_available_outlined),
    FieldSpec('deliveryStatus', 'Delivery Status', icon: Icons.flag_outlined, options: ['Pending', 'Dispatched', 'Delivered']),
    FieldSpec('deliveryAddress', 'Delivery Address', icon: Icons.location_on_outlined, lines: 2),
    FieldSpec('transportMode', 'Transport Mode', icon: Icons.local_shipping_outlined, options: ['Our Transport', 'Farmer Pickup', 'Third Party']),
    FieldSpec('driverContact', 'Driver Contact', icon: Icons.phone_outlined, keyboard: _phone),
    FieldSpec('deliveryRemarks', 'Remarks', icon: Icons.notes_rounded, lines: 2),
  ]),
  StepSpec('Warranty & Service', 'Post sales support', Icons.handyman_outlined, [
    FieldSpec('warrantyPeriod', 'Warranty Period', icon: Icons.shield_outlined, options: ['6 Months', '1 Year', '2 Years', '3 Years']),
    FieldSpec('warrantyStart', 'Start Date', icon: Icons.event_outlined),
    FieldSpec('warrantyEnd', 'End Date', icon: Icons.event_busy_outlined),
    FieldSpec('warrantyStatus', 'Warranty Status', icon: Icons.verified_user_outlined, options: ['Active', 'Expired', 'Not Applicable']),
    FieldSpec('serviceType', 'Service Type', icon: Icons.build_outlined, options: ['Free Service', 'Paid Service', 'Breakdown']),
    FieldSpec('serviceDate', 'Service Date', icon: Icons.event_outlined),
    FieldSpec('serviceEngineer', 'Service Engineer', icon: Icons.engineering_outlined),
    FieldSpec('serviceNotes', 'Service Notes', icon: Icons.notes_rounded, lines: 3),
  ]),
];
