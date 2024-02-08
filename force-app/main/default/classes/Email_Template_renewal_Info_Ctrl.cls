public class Email_Template_renewal_Info_Ctrl  {

   public Double ExpectedRenewal_ACV { get; set {
	ExpectedRenewal_ACV = value; 
	value.format();
   }}
   public Double  AcvDownSell_Amount {get; set;}
   public Double  AcvDownSell_Percent {get; set;}
   public Double  AcvDifference_Amount {get; set;}
   public Double AcvDifference_Percent {get; set;}
   public Double UpliftedExpected_RenewalACV {get; set;}
   public String currencyISO {get; set;}

   public String Expected_Renewal_ACV {get{
	return ExpectedRenewal_ACV.format();
   } set;}

      public String Acv_DownSell_Amount {get{
	return AcvDownSell_Amount.format();
   } set;}

      public String Acv_DownSell_Percent {get{
	return AcvDownSell_Percent.format();
   } set;}

      public String Acv_Difference_Amount {get{
	return AcvDifference_Amount.format();
   } set;}

      public String Acv_Difference_Percent {get{
	return AcvDifference_Amount.format();
   } set;}

      public String Uplifted_ExpectedRenewal_ACV {get{
	return UpliftedExpected_RenewalACV.format();
   } set;}


}