<template>
  <div class="container">
    <div class="title">
      <span class="emoji">🏠</span>
      <span>Прогноз цен на двухкомнатные квартиры</span>
    </div>

    <h2 class="sub">Прогноз временных рядов на основе SARIMA</h2>

    <div class="controls">
      <label>Прогноз на будущие месяцы:</label>
      <select v-model.number="months">
        <option v-for="m in options" :key="m" :value="m">{{ m }} месяцев</option>
      </select>

      <button @click="loadForecast" :disabled="loading">
        {{ loading ? "Загрузка..." : "Начать прогноз" }}
      </button>
    </div>

    <div class="hint">
      Синяя линия — исторические цены; оранжевая — прогноз; область справа от пунктирной линии — прогнозный период
    </div>

    <div ref="chartDiv" class="chart"></div>
  </div>
</template>

<script>
import * as echarts from "echarts";

export default {
  data() {
    return {
      months: 12,
      options: [3, 6, 12, 24, 36],
      loading: false,
      chart: null,
      baseHistory: [], // 缓存历史数据
    };
  },

  async mounted() {
    this.chart = echarts.init(this.$refs.chartDiv);
    window.addEventListener("resize", this.resizeChart);

    // 页面加载时先画“只有历史数据”的图
    await this.loadInitialHistory();
  },

  beforeUnmount() {
    window.removeEventListener("resize", this.resizeChart);
    if (this.chart) {
      this.chart.dispose();
      this.chart = null;
    }
  },

  methods: {
    resizeChart() {
      if (this.chart) {
        this.chart.resize();
      }
    },

    // 初次加载：只显示历史数据
    async loadInitialHistory() {
      try {
        const url = `http://127.0.0.1:8000/forecast?months=${this.months}`;
        const resp = await fetch(url);
        const data = await resp.json();

        this.baseHistory = data.history || [];
        this.renderChart(this.baseHistory, []); // 只画历史线
      } catch (e) {
        console.error("Не удалось загрузить исторические данные:", e);
      }
    },

    // 点击按钮：加载预测
    async loadForecast() {
      this.loading = true;
      try {
        const url = `http://127.0.0.1:8000/forecast?months=${this.months}`;
        const resp = await fetch(url);
        const data = await resp.json();

        const history =
          data.history && data.history.length > 0
            ? data.history
            : this.baseHistory;
        const forecast = data.forecast || [];

        this.baseHistory = history;
        this.renderChart(history, forecast);
      } catch (e) {
        console.error("Не удалось загрузить прогноз:", e);
      } finally {
        this.loading = false;
      }
    },

    renderChart(history, forecast) {
      if (!this.chart) {
        this.chart = echarts.init(this.$refs.chartDiv);
      }

      // 历史数据点：[date, price]
      const historyPoints = history.map((item) => [item.date, item.price]);

      // 预测数据点：[date, price]
      let forecastPoints = forecast.map((item) => [item.date, item.price]);

      // 让历史和预测在最后一个历史点“碰头”，不要中间空一段
      if (historyPoints.length > 0 && forecastPoints.length > 0) {
        const lastHistory = historyPoints[historyPoints.length - 1];
        const firstForecast = forecastPoints[0];

        if (lastHistory[0] !== firstForecast[0]) {
          forecastPoints.unshift([lastHistory[0], lastHistory[1]]);
        }
      }

      const forecastStart =
        forecastPoints.length > 0 ? forecastPoints[0][0] : null;

      const allPoints = [...historyPoints, ...forecastPoints];

      const option = {
        backgroundColor: "#111",
        title: {
          text: "Прогноз цен на жильё (средняя цена)",
          left: "center",
          top: 10,
          textStyle: {
            color: "#fff",
            fontSize: 18,
          },
        },
        tooltip: {
          trigger: "item",
          axisPointer: { type: "line" },
          formatter(params) {
            // 只对折线系列的真实数据点显示 tooltip，
            // 对 markLine / markArea 等返回空字符串，避免 NaN-NaN, NaN
            if (
              params.componentType !== "series" ||               // 不是折线系列
              !Array.isArray(params.data) ||                     // data 不是数组
              params.data.length < 2 ||                          // 没有 [date, price]
              params.data[0] == null || params.data[1] == null   // 有空值
            ) {
              return "";
            }

            const d = new Date(params.data[0]);
            if (Number.isNaN(d.getTime())) return "";

            const year = d.getFullYear();
            const month = String(d.getMonth() + 1).padStart(2, "0");
            const price = Math.round(params.data[1]).toLocaleString();
            return `${year}-${month} | ${price}`;
          },
        },
        legend: {
          data: ["Исторические данные", "Прогноз"],
          bottom: 10,
          textStyle: { color: "#fff" },
        },
        grid: {
          left: 60,
          right: 40,
          top: 80,
          bottom: 60,
        },
        xAxis: {
          type: "time",
          boundaryGap: false,
          axisLine: { lineStyle: { color: "#888" } },
          axisLabel: {
            color: "#bbb",
          },
          min: allPoints.length > 0 ? allPoints[0][0] : null,
          max:
            allPoints.length > 0
              ? allPoints[allPoints.length - 1][0]
              : null,
        },
        yAxis: {
          type: "value",
          axisLine: { lineStyle: { color: "#888" } },
          axisLabel: {
            color: "#bbb",
            formatter: (v) => v.toLocaleString(),
          },
          splitLine: {
            lineStyle: { color: "#333" },
          },
        },
        series: [
          {
            name: "Исторические данные",
            type: "line",
            data: historyPoints,
            smooth: true,
            symbol: "circle",
            symbolSize: 4,
            lineStyle: {
              width: 2,
              color: "#4ea5ff",
            },
            itemStyle: {
              color: "#4ea5ff",
            },
            animationDuration: 600,
          },
          {
            name: "Прогноз",
            type: "line",
            data: forecastPoints,
            smooth: true,
            symbol: "circle",
            symbolSize: 4,
            lineStyle: {
              width: 2,
              type: "dashed",
              color: "#ffa940",
            },
            itemStyle: {
              color: "#ffa940",
            },
            animationDuration: 800,
          },
        ],
      };

      if (forecastStart) {
        option.series[0].markLine = {
          symbol: "none",
          data: [
            {
              xAxis: forecastStart,
              lineStyle: {
                color: "#ffa940",
                type: "dashed",
              },
              label: {
                show: true,
                formatter: "Начало прогноза",
                color: "#ffa940",
                position: "end",
              },
            },
          ],
        };

        option.series[0].markArea = {
          itemStyle: {
            color: "rgba(255, 169, 64, 0.08)",
          },
          data: [
            [
              { xAxis: forecastStart },
              {
                xAxis:
                  forecastPoints.length > 0
                    ? forecastPoints[forecastPoints.length - 1][0]
                    : forecastStart,
              },
            ],
          ],
        };
      }

      this.chart.setOption(option, true);
      this.chart.resize();
    },
  },
};
</script>

<style>
body {
  margin: 0;
  background-color: #111;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue",
    Arial, "Noto Sans", "PingFang SC", "Hiragino Sans GB", "Microsoft YaHei", sans-serif;
}

.container {
  max-width: 2000px;
  margin: 0 auto;
  text-align: center;
  padding: 40px 20px 60px;
  color: #fff;
}

.title {
  display: flex;
  justify-content: center;
  align-items: center;
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 10px;
}

.title .emoji {
  font-size: 40px;
  margin-right: 10px;
}

.sub {
  margin-bottom: 30px;
  opacity: 0.85;
}

.controls {
  margin-bottom: 10px;
}

.controls label {
  margin-right: 8px;
}

.controls select,
.controls button {
  padding: 8px 12px;
  margin: 5px;
  font-size: 16px;
  border-radius: 6px;
  border: none;
}

.controls select {
  background: #222;
  color: #fff;
}

.controls button {
  background: #3b82f6;
  color: #fff;
  cursor: pointer;
}

.controls button:disabled {
  opacity: 0.6;
  cursor: default;
}

.hint {
  font-size: 13px;
  color: #aaa;
  margin-bottom: 10px;
}

.chart {
  width: 80vw;
  max-width: 1400px;
  height: 500px;
  margin: 0 auto;
  background: #1a1a1a;
  border-radius: 10px;
}
</style>
