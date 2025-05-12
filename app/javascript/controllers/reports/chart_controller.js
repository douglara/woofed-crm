import { Controller } from "stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static values = {
    chartType: String,
    chartData: Object,
  };
  connect() {
    var options =
      this.chartTypeValue === "funnel"
        ? this.funnelChartType()
        : this.columnChartType();

    if (typeof ApexCharts !== "undefined") {
      this.chart = new ApexCharts(this.element, options);
      this.chart.render();
    }
  }
  funnelChartType() {
    return {
      series: this.chartDataValue.series,
      chart: {
        type: "bar",
        height: 350,
        dropShadow: {
          enabled: true,
        },
      },
      colors: ["#6857D9"],
      legend: {
        show: true,
      },
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
        formatter: function (val, opt) {
          return opt.w.globals.labels[opt.dataPointIndex] + ":  " + val;
        },
        dropShadow: {
          enabled: true,
        },
      },

      xaxis: {
        categories: this.chartDataValue.categories,
      },
      legend: {
        show: false,
      },
    };
  }
  columnChartType() {
    return {
      series: this.chartDataValue.series,
      chart: {
        type: "bar",
        height: 350,
      },
      colors: ["#259C50", "#CF4F27"],
      legend: {
        show: true,
      },
      plotOptions: {
        bar: {
          horizontal: false,
          columnWidth: "55%",
          borderRadius: 5,
          borderRadiusApplication: "end",
        },
      },
      dataLabels: {
        enabled: false,
      },
      stroke: {
        show: true,
        width: 2,
        colors: ["transparent"],
      },
      xaxis: {
        categories: this.chartDataValue.categories,
      },
      fill: {
        opacity: 1,
      },
      tooltip: {
        enabled: true,
      },
    };
  }
  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
}
