#property copyright "Adam Parusel"
#property link      "https://adamparusel.com"
#property version   "1.00"
#property strict
#property indicator_chart_window

input float    RiskPercentage = 2.0;
input int      RiskAbsolute = 500;
input color    labelColor = Silver;

int OnInit()
{
   findOrCreateStopLoss();
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{
   ObjectDelete("stopLossLine");
   ObjectDelete("stopLossDistance");
   ObjectDelete("riskAbsolute");
   ObjectDelete("riskRelative");
}

void OnChartEvent(const int id,const long &lparam,const double &dparam,const string &sparam)
{
   if(id==CHARTEVENT_OBJECT_DRAG){
      if(sparam=="stopLossLine"){
         printValues();
      }
   }
}


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
   findOrCreateStopLoss();
   printValues();
   return(rates_total);
}

double findOrCreateStopLoss()
{
   int stopLossLine = ObjectFind("stopLossLine");

   if (stopLossLine < 0 ) {
      Print("Stop loss line not found. Creating one.");

      double priceMin = ChartGetDouble(0,CHART_PRICE_MIN);
      double priceMax = ChartGetDouble(0,CHART_PRICE_MAX);
      double priceAvg = (priceMax+priceMin) / 2;
     
      ObjectCreate("stopLossLine", OBJ_HLINE, 0,0, priceAvg);
      return getNormalizedPrice(priceAvg);
   }

   return getNormalizedPrice(ObjectGetDouble(0, "stopLossLine", OBJPROP_PRICE1));
}

void printValues()
{
   double stopLossDistanceInPoints = 0;
   double stopLoss = findOrCreateStopLoss();

   if (stopLoss > Bid) {
      stopLossDistanceInPoints = MathFloor((stopLoss - Bid) / Point);
   } else {
      stopLossDistanceInPoints = MathFloor((Ask - stopLoss) / Point);
   }
   
   double riskAbsoluteFromPercentage = MathRound(RiskPercentage * AccountBalance()) / 100;
   double riskPercentageFromAbsolute = MathRound((RiskAbsolute / AccountBalance()) * 100 * 100) / 100;

   createLabelIfNotExist("stopLossDistance", "SL distance: ", CORNER_RIGHT_UPPER, 50, 25, 12, labelColor);   
   ObjectSetText("stopLossDistance", "SL distance: " + DoubleToStr(stopLossDistanceInPoints * Point, 2));

   createLabelIfNotExist("riskAbsolute", "Risk absolute", CORNER_RIGHT_UPPER, 50, 75, 12, labelColor);
   ObjectSetText("riskAbsolute", "Absolute risk (" + RiskAbsolute + " " + AccountCurrency() + " = " + riskPercentageFromAbsolute + "%): "
      + DoubleToStr(calculateLotSizeOnAbsoluteRiskAmount(RiskAbsolute, stopLossDistanceInPoints), 2));

   createLabelIfNotExist("riskRelative", "Risk relative", CORNER_RIGHT_UPPER, 50, 125, 12, labelColor);
   ObjectSetText("riskRelative", "Relative risk (" + RiskPercentage + "% = " + riskAbsoluteFromPercentage + " " + AccountCurrency() + "): "
      + DoubleToStr(calculateLotSizeOnAbsoluteRiskAmount(riskAbsoluteFromPercentage, stopLossDistanceInPoints), 2));
}

double getNormalizedPrice(double price)
{
   return MathRound(price / Point) * Point;
}

double calculateLotSizeOnAbsoluteRiskAmount(double amount, double distance)
{
   double tickvalue=MarketInfo(Symbol(), MODE_TICKVALUE);
   double riskPerOneLot = tickvalue * distance;

   return MathRound(100 * amount / riskPerOneLot) / 100;
}

void createLabelIfNotExist(string name, string text, int corner, int xPos, int yPos, int size, color col)
{
   if(ObjectFind(name) < 0) {
      ObjectCreate(name, OBJ_LABEL, 0, 0,0,0,0);
      ObjectSet(name, OBJPROP_XDISTANCE, xPos);
      ObjectSet(name, OBJPROP_YDISTANCE, yPos);
      ObjectSet(name, OBJPROP_CORNER, corner);

      ObjectSetText(name, text, size, "Arial", col);
   }
}

void createEditIfNotExist(string name, string text, int corner, int xPos, int yPos, int size, color col)
{
   if(ObjectFind(name) < 0) {
      ObjectCreate(name, OBJ_EDIT, 0, 0,0,0,0);
      ObjectSet(name, OBJPROP_XDISTANCE, xPos);
      ObjectSet(name, OBJPROP_YDISTANCE, yPos);
      ObjectSet(name, OBJPROP_CORNER, corner);

      ObjectSetText(name, text, size, "Arial", col);
   }
}