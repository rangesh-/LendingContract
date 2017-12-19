pragma solidity ^0.4.11;

/*LendingContract - P2P Lending system between borrower and investor,
borrower needs to purchase loan gurantee that should atleast worth half
of the loan amount. the loan gurantee brings the trust that is needed among the participants.
*/
contract LendingContract{
   //
   
   uint256 private rateofinterestnumerator = 17 ;
   uint256 private rateofinterestdenominator= 2 ;
   uint256 private noofinstallments=3;
   uint256 private valueofloanguarantee =1; // In ether
   uint256 private totalloanguarantee =100000000; //hardcoded for simple usecase.
   address private _owner ;    

//Hold Loan Details
    struct LoanDetails {
         address loanrequestor;
         address loanprovider;
         uint256 amountrequested;
         uint256 amountrepayed;
         uint256 nextinstallementperiod;  
         uint256 installmentcount;
         uint256 amountpaidperinstallment;       
         bool isdefault;
         bool isAccepted;
         bool isLoanclosed;
         bool isLoanRequested; 
    }  
      
      //1 Investor/Funder can map to many borrower
     // Hold to whom the money is lended to,this is neccessary for investor to all of borrower address   
    struct LendedLoanDetails{
        address lenderaddress;
        uint256 amountlended;        
    }
     
    
    mapping(address=>uint256) loanguarantee;
    //      //1 Investor/Funder can map to many borrower
    mapping(address=>LendedLoanDetails[]) listofloansbyfunders;
    mapping(address=>LoanDetails) loandetails; 
    LoanDetails[] listofloans;
    address[] loanaddress;
    uint256[] loanamount;

    modifier IsValidLoanRequest(){
      require(loanguarantee[msg.sender] > 0 );
      _;
    }
     
     modifier IsLoanOpen(){
         require(loandetails[msg.sender].isLoanclosed == true);
         _;
     }

     modifier onlyOwner(){
         require(msg.sender == _owner);
         _;
     }
 

     function  LendingContract() {
       _owner = msg.sender;
       loanguarantee[_owner] = totalloanguarantee; // hardcoded for simpleusecase
     }


    //Request Loan module invoked by borrower
    
    function RequestLoan(uint256 amount) public IsValidLoanRequest() {
      require(loanguarantee[msg.sender] >= amount/2 );  
      var newloandetails =  LoanDetails({loanrequestor:msg.sender, amountrequested : amount ,amountrepayed:0,nextinstallementperiod:0,installmentcount:0,amountpaidperinstallment: (amount * ((1 ether * rateofinterestnumerator) /rateofinterestdenominator)/noofinstallments), isLoanRequested :true,isdefault:false,isAccepted :false,isLoanclosed :false,loanprovider:msg.sender});
      listofloans.push(newloandetails);
      loandetails[msg.sender] = newloandetails;
    }

    //Display list of loans requested - Investors can lend money based upon interest
    function getListofLoan() public returns(address[],uint256[]) {
        for (uint8 index = 0; index < listofloans.length; index++) {
            if(listofloans[index].isLoanRequested == true && listofloans[index].isAccepted == false ) {
                loanaddress.push(listofloans[index].loanrequestor);
                loanamount.push(listofloans[index].amountrequested);
            }
        }
        return(loanaddress,loanamount);

    } 
    
    // Investor Lending Money to borrower upon his interest - Payable function

    function AcceptLoan(address fundowner,address fundreceiver,uint256 amount) public payable {     
     require(loanguarantee[fundreceiver] >= amount/2 );
      var istransfersuccessful = fundreceiver.send(amount * 1 ether);   
      if (istransfersuccessful) {
       addLoanpaymentDetails(fundowner,fundreceiver,amount);
      }
    }

   // Add and configure LoanPaymentDetails
    function addLoanpaymentDetails (address fundowner,address fundreceiver,uint256 amount) private {
     var prevloandetailsoffunder = listofloansbyfunders[fundowner];
     var loan =LendedLoanDetails({ lenderaddress : fundreceiver, amountlended : amount});
     prevloandetailsoffunder.push(loan);
     listofloansbyfunders[fundowner] = prevloandetailsoffunder;
     var loandetailsoflenderer = loandetails[fundreceiver];
     loandetailsoflenderer.nextinstallementperiod = now * 30 days ; 
     loandetailsoflenderer.isAccepted = true;
     loandetailsoflenderer.loanprovider = fundowner;
     loandetails[fundreceiver] = loandetailsoflenderer;
    }
  
    // LoanRepayment by borrower to Investor;
    function repayLoan(address lender,address tobepayed,uint256 amount) IsLoanOpen() public payable{
       require(loandetails[lender].amountpaidperinstallment == amount); 
       var istransfersuccessful = tobepayed.send(amount * 1 ether);   
      if (istransfersuccessful) {
       addLoanRepaymentDetails(lender,amount); 
      }
       
    }
    
   //Loanrepaymentdetails
    function addLoanRepaymentDetails(address lender,uint256 amount) private {
         var loandetailsoflenderer = loandetails[lender];
         loandetailsoflenderer.nextinstallementperiod = now * 30 days ; 
         loandetailsoflenderer.installmentcount += 1;
         loandetailsoflenderer.amountrepayed += amount;
         closeLoan(lender);
    }
    
   //closeloan module
    function closeLoan(address lender) public {
      var loandetailsoflenderer = loandetails[lender];
      if ((loandetailsoflenderer.amountrepayed==loandetailsoflenderer.amountpaidperinstallment*noofinstallments) || loandetailsoflenderer.installmentcount == noofinstallments)
       loandetailsoflenderer.isLoanclosed =true;
    }
     
     //buyLoanguarantee to apply for loan
     function buyLoanguarantee(uint loanguaranteeneeded) payable public {
      
      require(loanguarantee[_owner]>=loanguaranteeneeded && loanguaranteeneeded >= valueofloanguarantee * 1 ether);
        loanguarantee[_owner] -= loanguaranteeneeded;
        loanguarantee[msg.sender] += loanguaranteeneeded;       
     }
     
     //If borrower did not pay the amount promised,get his token which can be converted to ether - This module is invoked by Inverstor for default cases
     
     function claimDefault(address defaulteraddress) public{
      var loandetailsoflenderer = loandetails[defaulteraddress];
      require(loandetailsoflenderer.loanprovider == msg.sender && now > loandetailsoflenderer.nextinstallementperiod);
      loanguarantee[msg.sender] += loanguarantee[defaulteraddress];
     }
     
     //getnextInstallmentdate for borrower to repay amount
     function getnextInstallmentdate() public returns(uint256){
         var loandetailsoflenderer = loandetails[msg.sender];
        return loandetailsoflenderer.nextinstallementperiod;
     }

     function setInterestrate(uint256 rofinumerator,uint256 roidenominator) public onlyOwner() {
      
      rateofinterestnumerator = rofinumerator;
      rateofinterestdenominator = roidenominator;
     }

     function setLoanInstallments(uint256 newInstallment) public onlyOwner() {
         noofinstallments = newInstallment;
     }

     function setValueofLoanguarantee(uint256 newvalue) public onlyOwner() {
         valueofloanguarantee = newvalue;
     }

}