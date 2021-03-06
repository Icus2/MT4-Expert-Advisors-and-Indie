//+------------------------------------------------------------------+
//|                                                       swing2.mq4 |
//|                                                             icus |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "icus"
#property link      "https://www.mql5.com"
#property version   "1.00"
#property strict
#include <stdlib.mqh>
#include <stderror.mqh>
//External Variables
extern bool DynamicLotsize=false;
extern double Equitypercent=2;
extern double Fixedlotsize=0.5;


extern int BuyTakeprofit=50;
extern int SellTakeprofit=50;

extern bool UseStoploss=False;
extern int Magicnumber=1234;
extern int Slippagepips=5;
extern int MaximumSL=1000;
//Rsi Settings
extern int Rsi_period=14;

//Trailing stop
extern bool UseTrailingStop=false;
extern int TrailingStop=15;
extern int TrailingStart=10;
extern int TrailingStep=10;
//---Breakeven
extern bool UseBreakEven=true;
extern int WhenToMoveToBe=10;
extern int LockProfit=2;
//Partial profits
extern int profit_level_1 = 10;
extern double partial_percent1=30;
extern int profit_level_2 = 40;
extern double partial_percent2=70;
extern bool Takepartialprofit=true;

extern double Rsi_Overbought=70;
extern double Rsi_Oversold=30;
extern double mfi_Oversold=20;
extern double mfi_Overbought=80;
extern int Vmalength=20;

//set zigzag
extern int ExtDepth=35;
extern int ExtDeviation=5;
extern int ExtBackstep=3;
//---- indicator buffers
double ExtMapBuffer[];
double ExtMapBuffer2[];
static datetime LastActiontime1;
static datetime LastActiontime2;



double lot_size_1;
double lot_size_2;

double lots;
double Partialslots;
double Usepoint;
int UseSlippage;
int BuyTicket;
int SellTicket;
int ErrorCode;
double Lotsize;
double Buystoploss;
double Sellstoploss;
bool TicketMod;
double SellTpprice;
double BuyTakeprofitprice;
double Openprice;
double  Calcslippage;
string ErrAlert;
string ErrLog;
double Closelotsize;

datetime time_array[];

double open_array[],high_array[],low_array[],close_array[];

long tick_volume_array[],volume_array[];

int spread_array[];
//+------------------------------------------------------------------+
//| Expert initialization function                                   |
//+------------------------------------------------------------------+
int OnInit()
  {
//---

   Usepoint=Pippoint(Symbol());
   UseSlippage=GetSlippage(Symbol(),Slippagepips);
//protectcode

//------------
   datetime TrialEndDate=D'2020.12.12';
   if(TimeCurrent()>TrialEndDate)
     {
      Alert("Trial period expired");
     }
   bool demo_account=IsDemo();
   if(!demo_account)
     {
      Alert("You cant use this with a real account");
      return(0);
     }


//---
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





//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
int start()
  {
//---

//Indie
   
   double Rsi_2=iRSI(Symbol(),0,Rsi_period,PRICE_CLOSE,2);
   double Rsi_1=iRSI(Symbol(),0,Rsi_period,PRICE_CLOSE,1);
   double mfi2=iMFI(Symbol(),0,Rsi_period,2);
   double mfi1=iMFI(Symbol(),0,Rsi_period,1);
   double Upvol1=iCustom(Symbol(),0,"up&dn",Vmalength,0,1,1,1);
   zigzag();

//+--------------------------------------------------------------------------+
//|Lotsize  Calculations                                                       |
//+--------------------------------------------------------------------------+

   if(DynamicLotsize==true)
     {
      double Risk_amount=AccountEquity()
                         *(Equitypercent/100);
      double Tickvalue=MarketInfo(Symbol(),MODE_TICKVALUE);
      if(Point==0.001||Point==0.00001)
         Tickvalue*=10;
      lots=(Risk_amount/50)/Tickvalue;
     }
   else
      lots=Fixedlotsize;
//----------------------------------------------------


   double valLow2= ExtMapBuffer[2];
   double valLow1= ExtMapBuffer[1];

   double valHigh2= ExtMapBuffer2[2];
   double valHigh1= ExtMapBuffer2[1];

   if(valLow2<=Low[2]||valLow1<=Low[1])
     {
      Alert("Lows matched");
     }
   if(valHigh2>=High[2]||valHigh1>=High[1])
     {
      Alert("Highs matched");
     }

//+----------------------------------------------------------------------------+
//|Partials closing lotsize
//+-----------------------------------------------------------------------------
   lot_size_1=(partial_percent1/100)*lots;
   lot_size_2=(partial_percent2/100)*lots;


//+-----------------------------------------------------------------------------+
//|Lotsize Verification                                                           |
//+-------------------------------------------------------------------------------+
   fnFormatLot(lots);
//---------------------------
//Break even and take partials
//+-----------------------------------
   if(UseTrailingStop)
      TrailOrder(TrailingStart, TrailingStop);
   if(UseBreakEven)
     {
      CheckBuyBreakEvenStop();
      CheckSellBreakEvenStop();
     }
   if(Takepartialprofit==true)
      fnPartialClose();


//+-------------------------------------------------+
//Check for Buy trades                              |      |
//+-------------------------------------------------+

   if(Volume[0]>1)
      return(0);

   if((mfi2<=mfi_Oversold||mfi1<=mfi_Oversold)&&(Rsi_1<=Rsi_Oversold||Rsi_2<=Rsi_Oversold)&&(valLow2==Low[2]||valLow1==Low[1]) && (Close[2]<Open[2]&&Open[1] < Close[1])&&(Volume[1]>Volume[2]))

     {
      while(IsTradeContextBusy())
         Sleep(10);
      RefreshRates();
      //Place Buy Order
      BuyTicket=(OrderSend(Symbol(),OP_BUY,lots,MarketInfo(Symbol(),MODE_ASK),UseSlippage,0,0,"Buy Order",Magicnumber,0,Green));

      // Error Handling
      if(BuyTicket==-1)
        {
         ErrorCode=GetLastError();

         ErrAlert=StringConcatenate("Open Buy Order-Error",ErrorCode);
         Alert(ErrAlert);
         ErrLog=StringConcatenate("Bid: ",MarketInfo(Symbol(),MODE_BID),"Ask: ",MarketInfo(Symbol(),MODE_ASK),"lots: ",lots);
         Print(ErrLog);
        }


      //+------------------------------------------------+
      //Modify Buytrades                                 |
      //+-------------------------------------------------+
      else
        {
         OrderSelect(BuyTicket,SELECT_BY_TICKET);
         int lowest_shift=iLowest(Symbol(),0,MODE_LOW,2,1);
         double Minstop=50*Usepoint;
         double Calbuysl=Low[lowest_shift]-Minstop;
         Openprice=OrderOpenPrice();
         //Calculatestoplevel
         double Stoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;

         RefreshRates();
         double UpperStoplevel=Ask + Stoplevel;
         double LowerStoplevel=Bid - Stoplevel;

         double Maxslprice=Openprice-(MaximumSL*Usepoint);

         //Verify Buystoploss
         if(Calbuysl>LowerStoplevel)
           {
            Buystoploss=LowerStoplevel-Minstop;
           }

         else
            if(Calbuysl<Maxslprice)
              {
               Buystoploss=Maxslprice;
              }
            else(Buystoploss=Calbuysl);

         //+-------------------------------------+
         //Calculate Buy Takeprofit              |
         //+--------------------------------------
         if(BuyTakeprofit>0)
            BuyTakeprofitprice=Openprice+(BuyTakeprofit*Usepoint);


         //+--------------------------------------------+
         //Modify trades                                |
         //+--------------------------------------------+
         if(IsTradeContextBusy())
            Sleep(10);
         if(MaximumSL>0 || BuyTakeprofit>0)
           {
            TicketMod=OrderModify(BuyTicket,Openprice,Buystoploss,BuyTakeprofitprice,0);

           }


        }

     }

//+----------------------------------+
// Check for sell                    |
//+----------------------------------+
   if(Volume[0]>1)
      return(0);

   if((mfi1>=mfi_Overbought||mfi2>=mfi_Overbought)&&(Rsi_1>=Rsi_Overbought||Rsi_2>=Rsi_Overbought)&&(valHigh2==High[2]||valHigh1==High[1]) && (Close[2]>Open[2]&&Open[1] > Close[1])&&(Volume[1]>Volume[2]))


     {
      while(IsTradeContextBusy())
         Sleep(10);
      RefreshRates();
      SellTicket=(OrderSend(Symbol(),OP_SELL,lots,MarketInfo(Symbol(),MODE_BID),UseSlippage,0,0,"Sell Order",Magicnumber,0,Green));

      // Error Handling
      if(SellTicket==-1)
        {
         ErrorCode=GetLastError();

         ErrAlert=StringConcatenate("Open Sell Order-Error",ErrorCode);
         Alert(ErrAlert);
         ErrLog=StringConcatenate("Bid: ",MarketInfo(Symbol(),MODE_BID),"Ask: ",MarketInfo(Symbol(),MODE_ASK),"lots: ",Lotsize);
         Print(ErrLog);
        }

      else
        {
         //+-------------------------------------------------------------------|
         //Add stop loss                                                       +
         //+-------------------------------------------------------------------|
         OrderSelect(SellTicket,SELECT_BY_TICKET);
         Openprice=OrderOpenPrice();
         int highest_shift=iHighest(Symbol(),0,MODE_HIGH,2,1);
         double Minstop=50*Usepoint;
         double Calsellsl=High[highest_shift]+Minstop;
         Openprice=OrderOpenPrice();
         double Stoplevel=MarketInfo(Symbol(),MODE_STOPLEVEL)*Point;
         double Maxsellp=Openprice+(MaximumSL*Usepoint);
         RefreshRates();
         double UpperStoplevel=Ask + Stoplevel;
         double LowerStoplevel=Bid - Stoplevel;

         if(Calsellsl<UpperStoplevel)
           {
            Sellstoploss=UpperStoplevel+Minstop;
           }
         else
            if(Calsellsl>Maxsellp)
              {
               Sellstoploss=Maxsellp;
              }
            else
              {
               Sellstoploss=Calsellsl;
              }
         //+-----------------------------------------+
         //Sell Take profit                           |
         //+-----------------------------------------|
         if(SellTakeprofit>0)
            SellTpprice=Openprice-(SellTakeprofit*Usepoint);
           {
            if(IsTradeContextBusy())
               Sleep(10);
            //+--------------------------------------------+
            //Modify trades                                |
            //+--------------------------------------------+
            if(SellTakeprofit>0)

               //Modify Order
               TicketMod=OrderModify(SellTicket,Openprice,Sellstoploss,SellTpprice,0);

            //Error handling
            if(TicketMod==False)
              {
               ErrorCode=GetLastError();
               ErrAlert=StringConcatenate("Add stop/profit-Error",ErrorCode);
               Alert(ErrAlert);

               ErrLog=StringConcatenate("Bid: ",MarketInfo(OrderSymbol(),MODE_BID),"Ask: ",MarketInfo(OrderSymbol(),MODE_ASK),"Ticket: ",SellTicket,"Stop: ",Buystoploss,"Profit: ",BuyTakeprofit);
               Print(ErrLog);
              }
           }

        }
     }
   return(0);
  }





//------------------------------------------------------#
double Calcpoint;
double Pippoint(string argSymbol)
  {
   int CalcDigits=MarketInfo(argSymbol,MODE_DIGITS);
   if(CalcDigits==2||CalcDigits==3)
      Calcpoint=0.01;
   else
      if(CalcDigits==4||CalcDigits==5)
         Calcpoint=0.0001;
   return(Calcpoint);
  }

//+-----------------------------------------------|
//get Slippage points                                +
//+-----------------------------------------------|
int GetSlippage(string currency,int Slippagepips)
  {
   int Calcdigits=MarketInfo(currency,MODE_DIGITS);
   if(Calcdigits==2||Calcdigits==4)
      Calcslippage=Slippagepips;
   else
      if(Calcdigits==3||Calcdigits==5)
         Calcslippage=Slippagepips*10;
   return(Calcslippage);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void TrailOrder(double Trailingstart, double TrailingStop)
  {
   double ticket=0;
   double tStoploss=NormalizeDouble(OrderStopLoss(),Digits);
   int cnt;
   double sl=OrderStopLoss();
   RefreshRates();
   if(OrdersTotal()>0)
     {
      for(cnt=OrdersTotal(); cnt>=0; cnt--)
        {
         OrderSelect(cnt,SELECT_BY_POS,MODE_TRADES);
         if(OrderType()<=OP_SELL && OrderSymbol()==Symbol() && OrderMagicNumber()==Magicnumber)
           {
            if(OrderType()==OP_BUY)
              {
               if(Ask>NormalizeDouble(OrderOpenPrice()+TrailingStart*Usepoint,Digits) && tStoploss< NormalizeDouble(Bid-(TrailingStop+TrailingStep)*Usepoint,Digits))
                 {
                  tStoploss=NormalizeDouble(Bid-TrailingStop*Usepoint,Digits);
                  ticket=OrderModify(OrderTicket(),OrderOpenPrice(),tStoploss,OrderTakeProfit(),0);
                  if(ticket>0)
                    {
                     Print("TrailingStop #2 Activated: ",OrderSymbol(),": SL",tStoploss,":Bid",Bid);
                     return;
                    }
                 }
              }

            if(OrderType()==OP_SELL)
              {
               if(Bid<NormalizeDouble(OrderOpenPrice()-TrailingStart*Usepoint,Digits)&&(sl>(NormalizeDouble(Ask+(TrailingStop+TrailingStep)*Usepoint,Digits)))|| (OrderStopLoss()==0))
                 {
                  tStoploss=NormalizeDouble(Ask+TrailingStop*Usepoint,Digits);
                  ticket=OrderModify(OrderTicket(),OrderOpenPrice(),tStoploss,OrderTakeProfit(),0,Red);
                  if(ticket>0)
                    {
                     Print("Trailing #2 Activated:",OrderSymbol(),":SL",tStoploss,":Ask",Ask);
                     return;
                    }
                 }
              }
           }
        }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+----------------------------------------------------------------- -+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckBuyBreakEvenStop()
  {
   for(int b=OrdersTotal()-1; b>=0; b--)
     {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol())
            if(OrderType()==OP_BUY)
               if(OrderStopLoss()<OrderOpenPrice())
                  if(Ask>OrderOpenPrice()+ WhenToMoveToBe*Usepoint)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),(OrderOpenPrice()+LockProfit*Usepoint),OrderTakeProfit(),0);
                    }
     }
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void CheckSellBreakEvenStop()
  {
   for(int b=OrdersTotal()-1; b>=0; b--)
     {
      if(OrderSelect(b,SELECT_BY_POS,MODE_TRADES))
         if(OrderSymbol()==Symbol())
            if(OrderType()==OP_SELL)
               if(OrderStopLoss()>OrderOpenPrice())
                  if(Bid<OrderOpenPrice()- WhenToMoveToBe*Usepoint)
                    {
                     OrderModify(OrderTicket(),OrderOpenPrice(),(OrderOpenPrice()-LockProfit*Usepoint),OrderTakeProfit(),0);
                    }
     }
  }



//+------------------------------------------------------------------+
//|Verify lot size                                                                  |
//+------------------------------------------------------------------+!
double VerifyLotSize(double Lotsize)
  {
   if(Lotsize<MarketInfo(Symbol(),MODE_MINLOT))
     {
      Lotsize=MarketInfo(Symbol(),MODE_MINLOT);
     }
   else
      if(Lotsize>MarketInfo(Symbol(),MODE_MAXLOT))
        {
         Lotsize=MarketInfo(Symbol(),MODE_MAXLOT);
        }
   if(MarketInfo(Symbol(),MODE_LOTSTEP)==0.1)
     {
      Lotsize==NormalizeDouble(Lotsize,1);
     }
   else
      Lotsize=NormalizeDouble(Lotsize,2);
   return(Lotsize);
  }


//+------------------------------------------------------------------+
//|                                                                  |


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void fnPartialClose()
  {
   double close_lot_size=0;

// this variable will holds the total number of trades for the entire account
   int all_trades=OrdersTotal();

// use a for loop to cycle through all of the trades, from 0 up to all_trades
   for(int cnt=0; cnt<all_trades; cnt++)
     {
      // use OrderSelect to get the info for each trade, cnt=0 the first time, then 1, 2, .., etc
      // if OrderSelect fails it returns false, so we just continue
      if(OrderSelect(cnt, SELECT_BY_POS, MODE_TRADES) == false)
         continue;

      // compare the magic_number of our EA (as passed in as an input parameter) to the order’s magic number
      // if they are equal, increment my_trades
      if(Magicnumber == OrderMagicNumber())
        {
         if(OrderType() == OP_BUY)
           {
            // check each level
            if((Bid - OrderOpenPrice())  >= profit_level_1*Usepoint)
              {
               if(OrderLots() > lot_size_1)
                 {
                  close_lot_size = fnFormatLot(OrderLots() - lot_size_1);
                  OrderClose(OrderTicket(), close_lot_size, Bid, 3, Blue);
                  return;
                 }
              }

            // check each level
            if((Bid - OrderOpenPrice())  > Usepoint*profit_level_2)
              {
               if(OrderLots() > lot_size_2)
                 {
                  close_lot_size = fnFormatLot(OrderLots() - lot_size_2);
                  OrderClose(OrderTicket(), close_lot_size, Bid, 3, Blue);
                  return;
                 }
              }
           }

         if(OrderType() == OP_SELL)
           {
            // check each level
            if((OrderOpenPrice() - Ask)  >Usepoint* profit_level_1)
              {
               if(OrderLots() > lot_size_1)
                 {
                  close_lot_size = fnFormatLot(OrderLots() - lot_size_1);
                  OrderClose(OrderTicket(), close_lot_size, Ask, 3, Blue);
                  return;
                 }
              }

            // check each level
            if((OrderOpenPrice() - Ask)  >Usepoint* profit_level_2)
              {
               if(OrderLots() > lot_size_2)
                 {
                  close_lot_size = fnFormatLot(OrderLots() - lot_size_2);
                  OrderClose(OrderTicket(), close_lot_size, Ask, 3, Blue);
                  return;
                 }
              }
           }

        }

     }

  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double fnFormatLot(double dLots)
  {
   double min, max, step, lots;
   int lotdigits=1;

   step = MarketInfo(Symbol(), MODE_LOTSTEP);

   if(step == 0.01)
      lotdigits=2;

   if(step == 0.1)
      lotdigits=1;

   lots = StrToDouble(DoubleToStr(dLots, lotdigits));

   min = MarketInfo(Symbol(), MODE_MINLOT);
   if(lots < min)
      return(min);

   max = MarketInfo(Symbol(), MODE_MAXLOT);
   if(lots > max)
      return(max);

   return(lots);
  }

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+


//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void zigzag()
  {
  
  
   int nBarTF;
   nBarTF=iBars(Symbol(),0);
   
   if(ArraySize(ExtMapBuffer)<nBarTF)
   {
    ArraySetAsSeries(ExtMapBuffer,false);
   ArraySetAsSeries(ExtMapBuffer2,false);
   
   ArrayResize(ExtMapBuffer,nBarTF);
   ArrayResize(ExtMapBuffer2,nBarTF);
   }

   ArraySetAsSeries(ExtMapBuffer,true);
   ArraySetAsSeries(ExtMapBuffer2,true);
   ArraySetAsSeries(time_array,true);
   ArraySetAsSeries(open_array,true);
   ArraySetAsSeries(high_array,true);
   ArraySetAsSeries(low_array,true);
   ArraySetAsSeries(close_array,true);
   ArraySetAsSeries(tick_volume_array,true);
   ArraySetAsSeries(volume_array,true);
   ArraySetAsSeries(spread_array,true);




   ArrayResize(time_array,nBarTF);
   ArrayResize(open_array,nBarTF);
   ArrayResize(high_array,nBarTF);
   ArrayResize(low_array,nBarTF);
   ArrayResize(close_array,nBarTF);
   ArrayResize(tick_volume_array,nBarTF);
   ArrayResize(volume_array,nBarTF);
   ArrayResize(spread_array,nBarTF);

   CopyTime(Symbol(),0,0,nBarTF,time_array);
   CopyOpen(Symbol(),0,0,nBarTF,open_array);
   CopyHigh(Symbol(),0,0,nBarTF,high_array);
   CopyLow(Symbol(),0,0,nBarTF,low_array);
   CopyClose(Symbol(),0,0,nBarTF,close_array);
   CopyTickVolume(Symbol(),0,0,nBarTF,tick_volume_array);
   CopyRealVolume(Symbol(),0,0,nBarTF,volume_array);
   CopySpread(Symbol(),0,0,nBarTF,spread_array);


   
   int    shift, back,lasthighpos,lastlowpos;
   double val,res;
   double curlow,curhigh,lasthigh,lastlow;

   for(shift=Bars-ExtDepth; shift>=1; shift--)
     {
      val=Low[Lowest(NULL,0,MODE_LOW,ExtDepth,shift)];
      if(val==lastlow)
         val=0.0;
      else
        {
         lastlow=val;
         if((Low[shift]-val)>(ExtDeviation*Point))
            val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=ExtMapBuffer[shift+back];
               if((res!=0)&&(res>val))
                  ExtMapBuffer[shift+back]=0.0;
              }
           }
        }
      ExtMapBuffer[shift]=val;
      //--- high
      val=High[Highest(NULL,0,MODE_HIGH,ExtDepth,shift)];
      if(val==lasthigh)
         val=0.0;
      else
        {
         lasthigh=val;
         if((val-High[shift])>(ExtDeviation*Point))
            val=0.0;
         else
           {
            for(back=1; back<=ExtBackstep; back++)
              {
               res=ExtMapBuffer2[shift+back];
               if((res!=0)&&(res<val))
                  ExtMapBuffer2[shift+back]=0.0;
              }
           }
        }
      ExtMapBuffer2[shift]=val;
     }

// final cutting
   lasthigh=-1;
   lasthighpos=-1;
   lastlow=-1;
   lastlowpos=-1;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//+----------------------------------------------------------------

//+------------------------------------------------------------------+
