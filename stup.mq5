//+------------------------------------------------------------------+
//|                                                       medias.mq5 |
//|                                  Copyright 2023, MetaQuotes Ltd. |
//|                                             https://www.mql5.com |
//+------------------------------------------------------------------+
#property copyright "Copyright 2023, MetaQuotes Ltd."
#property link      "https://www.mql5.com"
#property version   "1.00"
#property indicator_chart_window
#property indicator_buffers 8
#property indicator_plots   3
#resource "\\Indicators\\volume_com_media.ex5"

//--- plot MM_lenta
#property indicator_label1  "MM_lenta"
#property indicator_type1   DRAW_LINE
#property indicator_color1  clrMagenta
#property indicator_style1  STYLE_SOLID
#property indicator_width1  2

//--- plot MM_rapida
#property indicator_label2  "MM_rapida"
#property indicator_type2   DRAW_COLOR_LINE
#property indicator_color2  clrLime, clrRed
#property indicator_style2  STYLE_SOLID
#property indicator_width2  2

//--- plot candles
#property indicator_label3 "cor_candles"
#property indicator_type3 DRAW_COLOR_CANDLES
#property indicator_color3 clrGreen, clrRed

//--- input parameters
input int      periodo_rapida          = 20;               // Período da média lenta
input int      periodo_lenta           = 200;              // Período da média rápida
input ENUM_MA_METHOD modo_rapida       = MODE_SMA;         // Tipo de média lenta
input ENUM_MA_METHOD modo_lenta        = MODE_SMA;         // Tipo de média rápida

//--- indicator buffers médias
double         MM_lentaBuffer[];
double         MM_rapidaBuffer[];
double         MM_rapida_colors_buffer[];

//--- indicator buffer candles
double Buffer_open[];
double Buffer_high[];
double Buffer_low[];
double Buffer_close[];
double Buffer_colors_candle[];

//---volume e média
double         Media_Buffer[];
double         volume_Buffer[];

int handle_Media_volume;
int handle_volume;

double Buffer_Media[];
double Buffer_volume[];
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+

//--- Médias móveis
int handle_rapida;
int handle_lenta;

double buffer_rapida[];
double buffer_lenta[];
double buffer_colors[];

//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//--- indicator buffers mapping
   SetIndexBuffer(0, MM_lentaBuffer, INDICATOR_DATA);
   SetIndexBuffer(1, MM_rapidaBuffer, INDICATOR_DATA);
   SetIndexBuffer(2, MM_rapida_colors_buffer, INDICATOR_COLOR_INDEX);

   SetIndexBuffer(3, Buffer_open, INDICATOR_DATA);
   SetIndexBuffer(4, Buffer_high, INDICATOR_DATA);
   SetIndexBuffer(5, Buffer_low, INDICATOR_DATA);
   SetIndexBuffer(6, Buffer_close, INDICATOR_DATA);
   SetIndexBuffer(7, Buffer_colors_candle, INDICATOR_COLOR_INDEX);

   IndicatorSetString(INDICATOR_SHORTNAME, "color");

   handle_rapida = iMA(_Symbol, PERIOD_CURRENT, periodo_rapida, 0, modo_rapida, PRICE_CLOSE);
   handle_lenta  = iMA(_Symbol, PERIOD_CURRENT, periodo_lenta, 0, modo_lenta, PRICE_CLOSE);

   handle_volume = iCustom(_Symbol, PERIOD_CURRENT, "::Indicators\\volume_com_media");

   ChartIndicatorAdd(0, 1, handle_volume);

   if(handle_rapida == INVALID_HANDLE || handle_lenta == INVALID_HANDLE)
     {
      Print("Erro ao executar o indicador");
      return INIT_FAILED;
     }
//---
   return (INIT_SUCCEEDED);
  }

//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
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
//---
   ArrayResize(buffer_colors, rates_total);
   ArrayResize(Buffer_colors_candle, rates_total);
   CopyBuffer(handle_volume, 0, 0, rates_total, Buffer_volume);
   CopyBuffer(handle_volume, 1, 0, rates_total, Media_Buffer);

   if(prev_calculated == 0)

     {

      CopyBuffer(handle_rapida, 0, 0, rates_total, buffer_rapida);
      CopyBuffer(handle_lenta, 0, 0, rates_total, buffer_lenta);

      for(int i = 0; i < rates_total; i++)
        {
         MM_rapidaBuffer[i]         = buffer_rapida[i];
         MM_lentaBuffer[i]          = buffer_lenta[i];
         MM_rapida_colors_buffer[i] = (buffer_rapida[i] < close[i])? 0:1;

         Buffer_open[i] = open[i];
         Buffer_high[i] = high[i];
         Buffer_low[i] = low[i];
         Buffer_close[i] = close[i];
         Buffer_colors_candle[i] = (buffer_rapida[i] < close[i]) ? 0 : 1;

        }
     }
   else
     {
      CopyBuffer(handle_rapida, 0, 0, rates_total, buffer_rapida);
      CopyBuffer(handle_lenta, 0, 0, rates_total, buffer_lenta);
      // não é necessario mudar a ordem da indexação use o [rates_total-1] que já é a barra atual, fica mais rapido o codigo
      if(buffer_rapida[rates_total - 1] > close[rates_total - 1])
        {
         buffer_colors[rates_total - 1] = 0;
        }
      else
        {
         buffer_colors[rates_total - 1] = 1;
        }

      MM_rapidaBuffer[rates_total - 1] = buffer_rapida[rates_total-1]; //correção prev_calculated. use em indicadores sempre o rates_total-1
      MM_lentaBuffer[rates_total - 1]  = buffer_lenta[rates_total-1];
      MM_rapida_colors_buffer[rates_total - 1] = (buffer_rapida[rates_total - 1] > close[rates_total - 1]);

      Buffer_open[rates_total - 1] = open[rates_total - 1];
      Buffer_high[rates_total - 1] = high[rates_total - 1];
      Buffer_low[rates_total - 1] = low[rates_total - 1];
      Buffer_close[rates_total - 1] = close[rates_total - 1];
      Buffer_colors_candle[rates_total - 1] = (buffer_rapida[rates_total - 1] < close[rates_total - 1]) ? 0 : 1;

     }
//--- return value of prev_calculated for next call
   return (rates_total);
  }
//+------------------------------------------------------------------+
