//+------------------------------------------------------------------+
//|                                            ea with Functions.mq4 |
//|                                                             icus |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "icus"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <functions.mqh>
#include <stdlib.mqh>

//External Variables
extern bool DynamicLotsize=true;
extern double Equitypercent=2;
extern double Fixedlotsize=0.1;
extern int no_of_bars=3;
extern int sell_bars=3;
extern double Takeprofit=100;
extern int Rsi_period=14;
extern int Vmalength=20;
extern int Magicnumber=1234;
extern int Slippagepips=5;
extern int MaximumSL=80;
extern int Rsi_Overbought=80;
extern int Rsi_Oversold=40;


double Usepoint;
int UseSlippage;
int BuyTicket;
int SellTicket;




//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---
   Usepoint=Pippoint(Symbol());
   UseSlippage=Getslippage(Symbol(),Slippagepips);
    
   
//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Expert deinitialization function                                 |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
//---

  }
//+------------------------------------------------------------------+
//| Expert tick function                                             |
//+------------------------------------------------------------------+
void OnTick()
  {
//---
  

   iCustom(Symbol(),0,"supportResistance",0,64,0,0,0);
   double Line1=ObjectGet("MM-2/8ths",OBJPROP_PRICE1);
   double Line2=ObjectGet("MM-1/8ths",OBJPROP_PRICE1);
   double Line3=ObjectGet("MM 0/8ths",OBJPROP_PRICE1);
   double Line4=ObjectGet("MM 1/8ths",OBJPROP_PRICE1);
   double Line5=ObjectGet("MM 2/8ths",OBJPROP_PRICE1);
   double Line6=ObjectGet("MM 3/8ths",OBJPROP_PRICE1);
   double Line7=ObjectGet("MM 4/8ths",OBJPROP_PRICE1);
   double Line8=ObjectGet("MM 5/8ths",OBJPROP_PRICE1);
   double Line9=ObjectGet("MM 6/8ths",OBJPROP_PRICE1);
   double Line10=ObjectGet("MM 7/8ths",OBJPROP_PRICE1);
   double Line11=ObjectGet("MM 8/8ths",OBJPROP_PRICE1);
   double Line12=ObjectGet("MM+1/8ths",OBJPROP_PRICE1);
   double Line13=ObjectGet("MM+2/8ths",OBJPROP_PRICE1);

//VMA
   double Dnvol2=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,0,2);
   double Upvol2=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,1,2);
   double Ma_vol2=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,2,2);
   double Dnvol1=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,0,1);
   double Upvol1=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,1,1);
   double Ma_vol1=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,2,1);
   
   //RSI
   double Rsi_2=iRSI(Symbol(),0,Rsi_period,PRICE_CLOSE,2);
  double Rsi_1=iRSI(Symbol(),0,Rsi_period,PRICE_CLOSE,1);




//Calculate Lotsize
   double Lotsize= Calc_lot_size(true,2,MaximumSL,0.1);
   double RealLS=VerifyLotSize(Lotsize);

//buy Order
//Condition for long
    
   if((( Rsi_2<=Rsi_Oversold||Rsi_1<=Rsi_Oversold)&&Low[2]<=(Line1||Line2||Line3||Line4||Line5||Line6||Line7||Line8||Line9||Line10||Line11||Line12||Line13) && Close[2]<Open[2] && Dnvol2>Ma_vol2 &&Close[1]>Open[1]  && Upvol1>=Dnvol2)||(Volume[0]>0&&( Rsi_2<=Rsi_Oversold||Rsi_1<=Rsi_Oversold)&&Close[2]<Open[2] && Dnvol2>Ma_vol2 &&Close[1]>Open[1]  && Upvol1>=Dnvol2 && Low[1]<=(Line1||Line2||Line3||Line4||Line5||Line6||Line7||Line8||Line9||Line10||Line11||Line12||Line13)))
    
     {
      if(SellTicket>0) int Closed=CloseSellOrder(Symbol(),SellTicket,Slippagepips);
      SellTicket=0;
      BuyTicket=OpenBuyOrder(Symbol(),RealLS,UseSlippage,Magicnumber);
      
      if(BuyTicket>0 && Takeprofit>0)
        {
          OrderSelect(BuyTicket,SELECT_BY_TICKET);
          double Openprice=OrderOpenPrice();
          double Buystoploss=CalcBuyStoploss(Symbol(),BuyTicket,3,MaximumSL);
          double Buytakeprofit=CalcTakeprofit(Symbol(),Takeprofit,Openprice);
          AddStopProfit(BuyTicket,Buystoploss,Buytakeprofit);
           double current_price=MarketInfo(Symbol(),MODE_BID);
          if(current_price>=Buytakeprofit||current_price<=Buystoploss)BuyTicket=0;
         }
        
       return;
    }
        
 
  
     
 


//Sell order
//Condition for short


  if(((Rsi_2>=Rsi_Overbought||Rsi_1>=Rsi_Overbought) && High[2]>=(Line1||Line2||Line3||Line4||Line5||Line6||Line7||Line8||Line9||Line10||Line11||Line12||Line13) && Close[2]>Open[2] && Upvol2>Ma_vol2 && Close[1]<Open[1]  && Dnvol1>=Upvol2)||(Volume[0]>0&&(Rsi_1>=Rsi_Overbought||Rsi_2>=Rsi_Overbought) && Close[2]>Open[2] && Upvol2>Ma_vol2 && High[1]>=(Line1||Line2||Line3||Line4||Line5||Line6||Line7||Line8||Line9||Line10||Line11||Line12||Line13)&& Dnvol1>=Upvol2 &&  Close[1]<Open[1]))
  {
         if(BuyTicket>0) Closed=CloseBuyOrder(Symbol(),BuyTicket,Slippagepips);
         BuyTicket=0;
         SellTicket=OpenSellOrder(Symbol(),RealLS,UseSlippage,Magicnumber);
         if(SellTicket>0 &&  Takeprofit>0)
             {
               OrderSelect(SellTicket,SELECT_BY_TICKET);
               double Openprice=OrderOpenPrice();
               double Sellstoploss=Sellstoploss(Symbol(),SellTicket,3,MaximumSL);
               double SellTakeprofit=CalcSellTakeprofit(Symbol(),Takeprofit,Openprice);
               AddStopProfit(SellTicket,Sellstoploss,SellTakeprofit);
               double currentSell_price=MarketInfo(Symbol(),MODE_ASK);
          if(currentSell_price<=SellTakeprofit||currentSell_price>=Sellstoploss)SellTicket=0;
             }
             return;
         }
   
     
 }
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
