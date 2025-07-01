import { Controller } from "stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static values = {
    chartData: Object,
  };

  static targets = ["chart"];

  connect() {
    if (typeof ApexCharts === "undefined") return;

    const options = this.getChartOptions();
    this.chart = new ApexCharts(this.chartTarget, options);
    this.chart.render();
  }

  disconnect() {
    this.chart?.destroy();
  }

  get chartType() {
    return this.chartDataValue.chart_type;
  }

  get chartColors() {
    return this.chartDataValue.data.map((item) => item.color);
  }

  getChartOptions() {
    return this.chartType === "funnel"
      ? this.getFunnelChartOptions()
      : this.getColumnChartOptions();
  }

  getFunnelChartOptions() {
    const firstSeries = this.chartDataValue.data?.[0];
    return {
      series: [
        {
          name: firstSeries?.name,
          data: Object.values(firstSeries?.series_data || {}),
        },
      ],
      chart: {
        type: "bar",
        height: 350,
        dropShadow: { enabled: true },
      },
      colors: this.chartColors,
      plotOptions: {
        bar: {
          borderRadius: 0,
          horizontal: true,
          barHeight: "80%",
          isFunnel: true,
        },
      },
      dataLabels: {
        enabled: true,
        formatter: (val, opt) =>
          `${opt.w.globals.labels[opt.dataPointIndex]}: ${val}`,
        dropShadow: { enabled: true },
      },
      xaxis: {
        categories: Object.keys(firstSeries?.series_data || {}),
      },
      legend: { show: false },
    };
  }

  getColumnChartOptions() {
    return {
      series: this.buildChartColumnSeries(),
      chart: {
        type: "bar",
        height: 350,
      },
      colors: this.chartColors,
      plotOptions: {
        bar: {
          horizontal: false,
          columnWidth: "55%",
          borderRadius: 5,
          borderRadiusApplication: "end",
        },
      },
      dataLabels: { enabled: false },
      stroke: {
        show: true,
        width: 2,
        colors: ["transparent"],
      },
      xaxis: {
        categories: this.getTimeseriesDates(
          this.chartDataValue?.data?.[0]?.series_data
        ),
      },
      fill: { opacity: 1 },
      tooltip: { enabled: true },
      legend: { show: true },
    };
  }

  buildChartColumnSeries() {
    return this.chartDataValue.data.map((item) => ({
      name: item.name,
      data: this.getTimeseriesValues(item.series_data),
    }));
  }

  getTimeseriesDates(data = []) {
    return data.map((item) =>
      new Date(item.timestamp * 1000).toLocaleDateString("sv-SE")
    );
  }

  getTimeseriesValues(data = []) {
    return data.map((item) => item.value);
  }
}
