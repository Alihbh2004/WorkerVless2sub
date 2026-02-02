//+------------------------------------------------------------------+
//|                                              ICT_OrderBlocks.mq5 |
//|                                  Copyright 2026, Gemini AI Model |
//|                                       https://www.google.com/    |
//+------------------------------------------------------------------+
#property copyright "Copyright 2026, Gemini AI"
#property link      "https://www.google.com/"
#property version   "6.06"
#property description "ICT Order Blocks - Delayed Deletion for Lines & Boxes"
#property indicator_chart_window
#property indicator_buffers 0
#property indicator_plots   0

#include <Arrays\ArrayObj.mqh>
#include <Object.mqh>

//--- INPUTS ---
input group ":: General Style Settings"
input color  defBullColor       = C'0,153,153';      // Default Bull Color (Teal)
input color  defBearColor       = C'128,0,0';        // Default Bear Color (Maroon)
input color  lineColor          = clrBlack;          // Daily/Weekly Line Color
input int    lineWidth          = 1;                 // Daily/Weekly Line Width
input bool   showLabels         = true;              // Show Labels
input int    maxActiveOBs       = 20;                // Max Active Memory per TF
input int    visibleOBCount     = 3;                 // Visible Count (Last N)
input int    mitigationDelay    = 3;                 // Mitigation Delay (Candles)
input color  mitigatedColor     = C'128,128,128';    // Mitigated Color
input int    transparency       = 100;               // Transparency (0-255, MQL5 style)

// --- 5 Minute Settings ---
input group ":: 5-Minute Settings"
input bool   show5m             = true;
input color  bullBox5m          = C'0,153,0';        // Green
input color  bearBox5m          = C'255,0,0';        // Red
input int    minChart5m         = 1;
input int    maxChart5m         = 5;

// --- 10 Minute Settings ---
input group ":: 10-Minute Settings"
input bool   show10m            = true;
input color  bullBox10m         = C'0,153,0';
input color  bearBox10m         = C'255,0,0';
input int    minChart10m        = 1;
input int    maxChart10m        = 5;

// --- 15 Minute Settings ---
input group ":: 15-Minute Settings"
input bool   show15m            = true;
input color  bullBox15m         = C'0,166,0';
input color  bearBox15m         = C'255,0,0';
input int    minChart15m        = 1;
input int    maxChart15m        = 10;

// --- 30 Minute Settings ---
input group ":: 30-Minute Settings"
input bool   show30m            = true;
input color  bullBox30m         = C'0,179,0';
input color  bearBox30m         = C'255,0,0';
input int    minChart30m        = 1;
input int    maxChart30m        = 15;

// --- 1 Hour Settings ---
input group ":: 1-Hour Settings"
input bool   show1H             = true;
input color  bullBox1H          = C'0,179,0';
input color  bearBox1H          = C'255,0,0';
input int    minChart1H         = 1;
input int    maxChart1H         = 30;

// --- 4 Hour Settings ---
input group ":: 4-Hour Settings"
input bool   show4H             = true;
input color  bullBox4H          = clrLime;
input color  bearBox4H          = clrMaroon;
input int    minChart4H         = 15;
input int    maxChart4H         = 60;

// --- Daily Settings ---
input group ":: Daily Settings"
input bool   showDaily          = true;
input int    minChartD          = 60;
input int    maxChartD          = 1440;

// --- Weekly Settings ---
input group ":: Weekly Settings"
input bool   showWeekly         = true;
input int    minChartW          = 240;
input int    maxChartW          = 10080;

// --- Dashboard ---
input group ":: Dashboard"
input bool   ShowDashboard      = true;
input color  DashBgColor        = C'30,30,30';
input color  DashTextColor      = clrWhite;

//--- ENUMS & CLASSES ---
enum ENUM_OB_TYPE { OB_RECTANGLE, OB_LINES };

class COrderBlock : public CObject
  {
public:
   double            priceTop;
   double            priceBottom;
   double            priceMid;       // For Lines
   datetime          timeStart;
   datetime          timeEnd;
   bool              isBullish;

   // General Mitigation (for Boxes)
   bool              isMitigated;
   datetime          mitigationTime;
   int               mitigationBarIdx;

   // Independent Line Mitigation (for D1/W1)
   bool              mitigatedTop;
   bool              mitigatedMid;
   bool              mitigatedBot;

   // Independent Timers for Lines
   datetime          tMitTop;
   datetime          tMitMid;
   datetime          tMitBot;

   ENUM_TIMEFRAMES   timeframe;
   ENUM_OB_TYPE      visualType;

   color             cBull;
   color             cBear;

   string            objNameBox;
   string            objNameLineTop;
   string            objNameLineMid;
   string            objNameLineBot;
   string            objNameLabel;

   bool              isActive;
   bool              isVisible;

   COrderBlock() : priceTop(0), priceBottom(0), priceMid(0), timeStart(0),
                   isBullish(false), isMitigated(false), isActive(true), isVisible(true),
                   mitigatedTop(false), mitigatedMid(false), mitigatedBot(false),
                   tMitTop(0), tMitMid(0), tMitBot(0) {}

   ~COrderBlock() { DeleteObjects(); }

   void UpdateVisuals(int transparency_val, int effectiveDelaySeconds)
     {
      if(!isVisible || !isActive) { DeleteObjects(); return; }

      // Dynamic Extension: Alive -> Extend; Mitigated -> Stop at mitigationTime
      // NOTE: For lines, we extend until individual line mitigation time
      datetime dEnd = TimeCurrent() + PeriodSeconds()*10;
      if(isMitigated && visualType == OB_RECTANGLE) dEnd = timeEnd;

      // Color Selection
      color c = isBullish ? cBull : cBear;

      // --- DRAWING ---
      if(visualType == OB_RECTANGLE)
      {
         // Standard Box Logic
         if(isMitigated) c = mitigatedColor;

         if(ObjectFind(0, objNameBox) < 0)
            ObjectCreate(0, objNameBox, OBJ_RECTANGLE, 0, timeStart, priceTop, dEnd, priceBottom);

         ObjectSetInteger(0, objNameBox, OBJPROP_TIME, 0, timeStart);
         ObjectSetDouble(0, objNameBox, OBJPROP_PRICE, 0, priceTop);
         ObjectSetInteger(0, objNameBox, OBJPROP_TIME, 1, dEnd);
         ObjectSetDouble(0, objNameBox, OBJPROP_PRICE, 1, priceBottom);
         ObjectSetInteger(0, objNameBox, OBJPROP_COLOR, c);
         ObjectSetInteger(0, objNameBox, OBJPROP_FILL, true);
         ObjectSetInteger(0, objNameBox, OBJPROP_BACK, true);
      }
      else
      {
         // Independent Lines Logic (D1/W1)
         // Logic: If NOT mitigated, draw normal.
         // If Mitigated, draw 'mitigatedColor' UNTIL delay expires. Then delete.

         // TOP LINE
         if(!mitigatedTop)
            DrawLine(objNameLineTop, priceTop, c, dEnd);
         else if (TimeCurrent() - tMitTop <= effectiveDelaySeconds)
            DrawLine(objNameLineTop, priceTop, mitigatedColor, tMitTop, STYLE_DOT); // Frozen at hit time
         else
            ObjectDelete(0, objNameLineTop);

         // MID LINE
         if(!mitigatedMid)
            DrawLine(objNameLineMid, priceMid, c, dEnd, STYLE_DOT);
         else if (TimeCurrent() - tMitMid <= effectiveDelaySeconds)
            DrawLine(objNameLineMid, priceMid, mitigatedColor, tMitMid, STYLE_DOT);
         else
            ObjectDelete(0, objNameLineMid);

         // BOT LINE
         if(!mitigatedBot)
            DrawLine(objNameLineBot, priceBottom, c, dEnd);
         else if (TimeCurrent() - tMitBot <= effectiveDelaySeconds)
            DrawLine(objNameLineBot, priceBottom, mitigatedColor, tMitBot, STYLE_DOT);
         else
            ObjectDelete(0, objNameLineBot);
      }

      // LABELS
      if(showLabels && !isMitigated)
        {
         if(ObjectFind(0, objNameLabel) < 0)
            ObjectCreate(0, objNameLabel, OBJ_TEXT, 0, timeStart, isBullish ? priceBottom : priceTop);

         string tfStr = StringSubstr(EnumToString(timeframe), 7);
         string txt = "ob-" + tfStr;
         ObjectSetString(0, objNameLabel, OBJPROP_TEXT, txt);
         ObjectSetInteger(0, objNameLabel, OBJPROP_COLOR, (visualType == OB_LINES) ? lineColor : clrWhite);
         ObjectSetInteger(0, objNameLabel, OBJPROP_FONTSIZE, 8);
         ObjectSetInteger(0, objNameLabel, OBJPROP_TIME, timeStart);
         ObjectSetDouble(0, objNameLabel, OBJPROP_PRICE, isBullish ? priceBottom : priceTop);
         ObjectSetInteger(0, objNameLabel, OBJPROP_ANCHOR, isBullish ? ANCHOR_LEFT_UPPER : ANCHOR_LEFT_LOWER);
        }
      else
        {
         ObjectDelete(0, objNameLabel);
        }
     }

   void DrawLine(string name, double price, color clr, datetime tEnd, ENUM_LINE_STYLE style=STYLE_SOLID)
     {
      if(ObjectFind(0, name) < 0)
         ObjectCreate(0, name, OBJ_TREND, 0, timeStart, price, tEnd, price);

      ObjectSetInteger(0, name, OBJPROP_TIME, 0, timeStart);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 0, price);
      ObjectSetInteger(0, name, OBJPROP_TIME, 1, tEnd);
      ObjectSetDouble(0, name, OBJPROP_PRICE, 1, price);
      ObjectSetInteger(0, name, OBJPROP_COLOR, clr);
      ObjectSetInteger(0, name, OBJPROP_WIDTH, lineWidth);
      ObjectSetInteger(0, name, OBJPROP_STYLE, style);
      ObjectSetInteger(0, name, OBJPROP_RAY_RIGHT, false);
     }

   void DeleteObjects()
     {
      ObjectDelete(0, objNameBox);
      ObjectDelete(0, objNameLineTop);
      ObjectDelete(0, objNameLineMid);
      ObjectDelete(0, objNameLineBot);
      ObjectDelete(0, objNameLabel);
     }
  };

//--- GLOBALS ---
CArrayObj ListM5, ListM10, ListM15, ListM30, ListH1, ListH4, ListD1, ListW1;
datetime  lastBarTime[8];
string    prefix = "ICT_FINAL_";

//+------------------------------------------------------------------+
//| Init                                                             |
//+------------------------------------------------------------------+
int OnInit()
  {
   ObjectsDeleteAll(0, prefix);

   ListM5.FreeMode(true); ListM10.FreeMode(true); ListM15.FreeMode(true); ListM30.FreeMode(true);
   ListH1.FreeMode(true); ListH4.FreeMode(true); ListD1.FreeMode(true); ListW1.FreeMode(true);

   ArrayInitialize(lastBarTime, 0);
   EventSetTimer(1);
   return(INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Deinit                                                           |
//+------------------------------------------------------------------+
void OnDeinit(const int reason)
  {
   ObjectsDeleteAll(0, prefix);
   EventKillTimer();
   ListM5.Clear(); ListM10.Clear(); ListM15.Clear(); ListM30.Clear();
   ListH1.Clear(); ListH4.Clear(); ListD1.Clear(); ListW1.Clear();
  }

//+------------------------------------------------------------------+
//| Calculate                                                        |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {
   if(rates_total < 100) return 0;

   // Process each timeframe if new data arrived
   if(show5m)  ProcessTimeframe(PERIOD_M5,  ListM5,  0, bullBox5m, bearBox5m, minChart5m, maxChart5m);
   if(show10m) ProcessTimeframe(PERIOD_M10, ListM10, 1, bullBox10m, bearBox10m, minChart10m, maxChart10m);
   if(show15m) ProcessTimeframe(PERIOD_M15, ListM15, 2, bullBox15m, bearBox15m, minChart15m, maxChart15m);
   if(show30m) ProcessTimeframe(PERIOD_M30, ListM30, 3, bullBox30m, bearBox30m, minChart30m, maxChart30m);
   if(show1H)  ProcessTimeframe(PERIOD_H1,  ListH1,  4, bullBox1H, bearBox1H, minChart1H, maxChart1H);
   if(show4H)  ProcessTimeframe(PERIOD_H4,  ListH4,  5, bullBox4H, bearBox4H, minChart4H, maxChart4H);
   if(showDaily) ProcessTimeframe(PERIOD_D1, ListD1, 6, lineColor, lineColor, minChartD, maxChartD);
   if(showWeekly) ProcessTimeframe(PERIOD_W1, ListW1, 7, lineColor, lineColor, minChartW, maxChartW);

   UpdateDashboard();
   return(rates_total);
  }

void OnTimer() { ChartRedraw(); }

//+------------------------------------------------------------------+
//| Get Timeframe in Minutes (for Ratio Logic)                       |
//+------------------------------------------------------------------+
double GetPeriodMinutes(ENUM_TIMEFRAMES tf)
  {
   return (double)PeriodSeconds(tf) / 60.0;
  }

//+------------------------------------------------------------------+
//| Process Timeframe Logic                                          |
//+------------------------------------------------------------------+
void ProcessTimeframe(ENUM_TIMEFRAMES tf, CArrayObj &list, int idx, color cBull, color cBear, int minMin, int maxMin)
  {
   datetime currentBarTime = iTime(Symbol(), tf, 0);
   bool newBar = (lastBarTime[idx] != currentBarTime);

   // 1. Check Mitigation (Realtime)
   CheckMitigation(list, tf);

   // 2. Scan for New OBs
   if(newBar || list.Total() == 0)
     {
      lastBarTime[idx] = currentBarTime;
      ScanForOBs(tf, list, cBull, cBear);
     }

   // 3. Visibility
   ManageVisibility(list, tf, minMin, maxMin);
  }

//+------------------------------------------------------------------+
//| Core Algorithm: Updated to Full Range (OB + Breakout Wicks)      |
//+------------------------------------------------------------------+
void ScanForOBs(ENUM_TIMEFRAMES tf, CArrayObj &list, color cBull, color cBear)
  {
   MqlRates rates[];
   ArraySetAsSeries(rates, true);
   int copied = CopyRates(Symbol(), tf, 0, 300, rates);
   if(copied < 10) return;

   for(int i = 2; i < copied - 1; i++)
     {
      bool found = false;
      bool isBull = false;
      double obTop = 0;
      double obBot = 0;
      double obOpen = 0;
      double obClose = 0;
      datetime obTime = 0;

      // --- BULLISH OB LOGIC (Down Candle) ---
      if(rates[i].close < rates[i].open)
        {
         bool breakOnNext = (rates[i-1].close > rates[i].high);
         bool breakOn2nd  = (rates[i-2].close > rates[i].high);

         if(breakOnNext || breakOn2nd)
           {
            found = true;
            isBull = true;
            obTime = rates[i].time;
            obOpen = rates[i].open;
            obClose = rates[i].close;

            // NEW LOGIC FOR H4 AND BELOW: Include Breakout Wicks
            if(tf <= PERIOD_H4)
              {
               obTop = rates[i].high;
               obBot = rates[i].low;
               if(breakOnNext) obBot = MathMin(obBot, rates[i-1].low);
               else obBot = MathMin(obBot, MathMin(rates[i-1].low, rates[i-2].low));
              }
            else // D1/W1 uses standard candle High/Low
              {
               obTop = rates[i].high;
               obBot = rates[i].low;
              }
           }
        }

      // --- BEARISH OB LOGIC (Up Candle) ---
      else if(rates[i].close > rates[i].open)
        {
         bool breakOnNext = (rates[i-1].close < rates[i].low);
         bool breakOn2nd  = (rates[i-2].close < rates[i].low);

         if(breakOnNext || breakOn2nd)
           {
            found = true;
            isBull = false;
            obTime = rates[i].time;
            obOpen = rates[i].open;
            obClose = rates[i].close;

            // NEW LOGIC FOR H4 AND BELOW
            if(tf <= PERIOD_H4)
              {
               obBot = rates[i].low;
               obTop = rates[i].high;
               if(breakOnNext) obTop = MathMax(obTop, rates[i-1].high);
               else obTop = MathMax(obTop, MathMax(rates[i-1].high, rates[i-2].high));
              }
            else
              {
               obTop = rates[i].high;
               obBot = rates[i].low;
              }
           }
        }

      if(found)
        {
         AddOB(list, isBull, obTime, obTop, obBot, obOpen, obClose, tf, cBull, cBear);
        }
     }
  }

void AddOB(CArrayObj &list, bool bull, datetime t, double top, double bot, double open, double close, ENUM_TIMEFRAMES tf, color cbull, color cbear)
  {
   // Dupe Check
   for(int i=0; i<list.Total(); i++) {
      COrderBlock *ex = list.At(i);
      if(ex.timeStart == t && ex.isBullish == bull) return;
   }

   COrderBlock *ob = new COrderBlock();
   ob.isBullish = bull;
   ob.timeStart = t;
   ob.timeframe = tf;
   ob.cBull = cbull;
   ob.cBear = cbear;

   if(tf == PERIOD_D1 || tf == PERIOD_W1)
     {
      ob.visualType = OB_LINES;
      double midBody = (open + close) / 2.0;
      if(bull) {
         ob.priceTop = top;
         ob.priceMid = open;
         ob.priceBottom = midBody;
      } else {
         ob.priceTop = midBody;
         ob.priceMid = open;
         ob.priceBottom = bot;
      }
     }
   else
     {
      ob.visualType = OB_RECTANGLE;
      ob.priceTop = top;
      ob.priceBottom = bot;
     }

   string suffix = "_" + IntegerToString((long)t) + "_" + EnumToString(tf) + (bull?"_B":"_S");
   ob.objNameBox = prefix + "B" + suffix;
   ob.objNameLineTop = prefix + "T" + suffix;
   ob.objNameLineMid = prefix + "M" + suffix;
   ob.objNameLineBot = prefix + "Bo" + suffix;
   ob.objNameLabel = prefix + "L" + suffix;

   list.Add(ob);
  }

//+------------------------------------------------------------------+
//| Mitigation with Timeframe Ratio Delay                            |
//+------------------------------------------------------------------+
void CheckMitigation(CArrayObj &list, ENUM_TIMEFRAMES tf)
  {
   double curLow = iLow(Symbol(), PERIOD_CURRENT, 0);
   double curHigh = iHigh(Symbol(), PERIOD_CURRENT, 0);

   // Calculate Ratio for Delay
   double obMins = GetPeriodMinutes(tf);
   double chartMins = GetPeriodMinutes(Period());
   double ratio = (obMins > 0 && chartMins > 0) ? (obMins / chartMins) : 1.0;
   if(ratio < 1.0) ratio = 1.0;
   int effectiveDelay = (int)MathCeil(mitigationDelay * ratio);
   int effectiveDelaySeconds = effectiveDelay * PeriodSeconds(Period());

   for(int i=0; i<list.Total(); i++)
     {
      COrderBlock *ob = list.At(i);
      if(!ob.isActive) continue;

      // A) OB_LINES (Independent Mitigation Logic)
      if(ob.visualType == OB_LINES)
      {
         bool somethingHit = false;

         if(ob.isBullish)
         {
            if(!ob.mitigatedTop && curLow <= ob.priceTop)    { ob.mitigatedTop = true; ob.tMitTop = TimeCurrent(); somethingHit=true; }
            if(!ob.mitigatedMid && curLow <= ob.priceMid)    { ob.mitigatedMid = true; ob.tMitMid = TimeCurrent(); somethingHit=true; }
            if(!ob.mitigatedBot && curLow <= ob.priceBottom) { ob.mitigatedBot = true; ob.tMitBot = TimeCurrent(); somethingHit=true; }
         }
         else
         {
            if(!ob.mitigatedTop && curHigh >= ob.priceTop)    { ob.mitigatedTop = true; ob.tMitTop = TimeCurrent(); somethingHit=true; }
            if(!ob.mitigatedMid && curHigh >= ob.priceMid)    { ob.mitigatedMid = true; ob.tMitMid = TimeCurrent(); somethingHit=true; }
            if(!ob.mitigatedBot && curHigh >= ob.priceBottom) { ob.mitigatedBot = true; ob.tMitBot = TimeCurrent(); somethingHit=true; }
         }

         // Only set FULL mitigation if all lines are old enough to be deleted
         bool allLinesDone = true;
         if(!ob.mitigatedTop || (TimeCurrent() - ob.tMitTop <= effectiveDelaySeconds)) allLinesDone = false;
         if(!ob.mitigatedMid || (TimeCurrent() - ob.tMitMid <= effectiveDelaySeconds)) allLinesDone = false;
         if(!ob.mitigatedBot || (TimeCurrent() - ob.tMitBot <= effectiveDelaySeconds)) allLinesDone = false;

         if(allLinesDone)
         {
            ob.isMitigated = true; // Signals full removal from memory in UpdateVisuals/List cleaning
         }
      }
      else
      // B) OB_RECTANGLE (Standard Box Logic)
      {
         // Touch Logic (Immediate Deletion)
         bool touched = false;
         if(ob.isBullish && curLow <= ob.priceTop) touched = true;
         if(!ob.isBullish && curHigh >= ob.priceBottom) touched = true;

         if(touched)
         {
            ob.isMitigated = true;
            ob.mitigationTime = TimeCurrent();
            ob.timeEnd = TimeCurrent();

            // IMMEDIATE DELETION REQUEST
            ob.isVisible = false;
            ob.isActive = false;
            ob.DeleteObjects(); // Ensure immediate removal
         }

         // Safety cleanup if already mitigated
         if(ob.isMitigated)
         {
             ob.isVisible = false;
             ob.isActive = false;
             ob.DeleteObjects();
         }
      }

      ob.UpdateVisuals(transparency, effectiveDelaySeconds);
     }
  }

//+------------------------------------------------------------------+
//| Visibility Manager                                               |
//+------------------------------------------------------------------+
void ManageVisibility(CArrayObj &list, ENUM_TIMEFRAMES tf, int minMin, int maxMin)
  {
   double chartMin = GetPeriodMinutes(Period());
   bool withinRange = (chartMin >= minMin && chartMin <= maxMin);

   // Hiding LTF OBs on HTF Charts (Strict Pine Logic)
   bool forceHide = false;
   double tfMin = GetPeriodMinutes(tf);

   if(tf == PERIOD_M5 && chartMin >= 10) forceHide = true;
   if(tf == PERIOD_M10 && chartMin >= 15) forceHide = true;
   if(tf == PERIOD_M15 && chartMin >= 30) forceHide = true;
   if(tf == PERIOD_M30 && chartMin >= 60) forceHide = true;
   if(tf == PERIOD_H1 && chartMin >= 240) forceHide = true;
   if(tf == PERIOD_H4 && chartMin >= 1440) forceHide = true;
   if(tf == PERIOD_D1 && chartMin >= 10080) forceHide = true;

   if(!withinRange) forceHide = true;

   int activeCount = 0;
   int visibleCount = 0;

   // Calculate Effective Delay Seconds for Visuals
   double obMins = GetPeriodMinutes(tf);
   double ratio = (obMins > 0 && chartMin > 0) ? (obMins / chartMin) : 1.0;
   if(ratio < 1.0) ratio = 1.0;
   int effectiveDelaySeconds = (int)MathCeil(mitigationDelay * ratio) * PeriodSeconds(Period());

   for(int i=0; i<list.Total(); i++)
     {
      COrderBlock *ob = list.At(i);

      if(forceHide)
        {
         ob.isVisible = false;
         ob.UpdateVisuals(transparency, effectiveDelaySeconds);
         continue;
        }

      if(!ob.isMitigated)
        {
         activeCount++;
         if(activeCount <= maxActiveOBs)
           {
            ob.isActive = true;
            if(visibleCount < visibleOBCount)
              {
               ob.isVisible = true;
               visibleCount++;
              }
            else ob.isVisible = false;
           }
         else
           {
            ob.isActive = false;
            ob.isVisible = false;
           }
        }
      // Mitigated: Visibility handled by Delay logic in CheckMitigation
      ob.UpdateVisuals(transparency, effectiveDelaySeconds);
     }
  }

//+------------------------------------------------------------------+
//| Dashboard                                                        |
//+------------------------------------------------------------------+
void UpdateDashboard()
  {
   if(!ShowDashboard) return;

   string bgName = prefix + "DashBG";
   if(ObjectFind(0, bgName) < 0)
     {
      ObjectCreate(0, bgName, OBJ_RECTANGLE_LABEL, 0, 0, 0);
      // FIXED: CORNER_LEFT_BOTTOM -> CORNER_LEFT_LOWER
      ObjectSetInteger(0, bgName, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, bgName, OBJPROP_XDISTANCE, 10);
      ObjectSetInteger(0, bgName, OBJPROP_YDISTANCE, 10);
      ObjectSetInteger(0, bgName, OBJPROP_XSIZE, 230);
      ObjectSetInteger(0, bgName, OBJPROP_YSIZE, 190);
      ObjectSetInteger(0, bgName, OBJPROP_BGCOLOR, DashBgColor);
      ObjectSetInteger(0, bgName, OBJPROP_BORDER_TYPE, BORDER_FLAT);
     }

   int y = 20; int step = 18;
   DrawDashRow("H", "Period", "Bearish", "Bullish", y, clrGray);
   DrawTFRow("W1", ListW1, y + step*1);
   DrawTFRow("D1", ListD1, y + step*2);
   DrawTFRow("H4", ListH4, y + step*3);
   DrawTFRow("H1", ListH1, y + step*4);
   DrawTFRow("M30", ListM30, y + step*5);
   DrawTFRow("M15", ListM15, y + step*6);
   DrawTFRow("M10", ListM10, y + step*7);
   DrawTFRow("M5", ListM5, y + step*8);
  }

void DrawTFRow(string tfName, CArrayObj &list, int y)
  {
   double minBear = 999999, minBull = 999999;
   double nBear = 0, nBull = 0;
   bool bMit = false, sMit = false;
   double price = SymbolInfoDouble(Symbol(), SYMBOL_BID);

   for(int i=0; i<list.Total(); i++)
     {
      COrderBlock *ob = list.At(i);
      // Logic: Find nearest visible/active
      // In Pine, it checks 'active_1' etc.
      if(!ob.isVisible) continue;

      if(ob.isBullish)
        {
         double d = MathAbs(price - ob.priceTop);
         if(d < minBull) { minBull = d; nBull = ob.priceTop; bMit = ob.isMitigated; }
        }
      else
        {
         double d = MathAbs(price - ob.priceBottom);
         if(d < minBear) { minBear = d; nBear = ob.priceBottom; sMit = ob.isMitigated; }
        }
     }

   string sBear = (nBear==0) ? "-" : DoubleToString(nBear, _Digits);
   if(sMit) sBear = "Hunted";
   string sBull = (nBull==0) ? "-" : DoubleToString(nBull, _Digits);
   if(bMit) sBull = "Hunted";

   DrawDashRow(tfName, tfName, sBear, sBull, y, DashTextColor);
  }

void DrawDashRow(string id, string c1, string c2, string c3, int y, color clr)
  {
   CreateLbl(prefix+"D1"+id, c1, 20, y, clr);
   CreateLbl(prefix+"D2"+id, c2, 80, y, (c2=="Hunted"?mitigatedColor:defBearColor));
   CreateLbl(prefix+"D3"+id, c3, 160, y, (c3=="Hunted"?mitigatedColor:defBullColor));
  }

void CreateLbl(string nm, string txt, int x, int y, color c)
  {
   if(ObjectFind(0, nm)<0) {
      ObjectCreate(0, nm, OBJ_LABEL, 0, 0, 0);
      // FIXED: CORNER_LEFT_BOTTOM -> CORNER_LEFT_LOWER
      ObjectSetInteger(0, nm, OBJPROP_CORNER, CORNER_LEFT_LOWER);
      ObjectSetInteger(0, nm, OBJPROP_XDISTANCE, x);
      ObjectSetInteger(0, nm, OBJPROP_FONTSIZE, 8);
   }
   ObjectSetInteger(0, nm, OBJPROP_YDISTANCE, y);
   ObjectSetString(0, nm, OBJPROP_TEXT, txt);
   ObjectSetInteger(0, nm, OBJPROP_COLOR, c);
  }
//+------------------------------------------------------------------+