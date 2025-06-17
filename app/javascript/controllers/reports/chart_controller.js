import { Controller } from "stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static values = {
    chartType: String,
    wonDealsData: Array,
    lostDealsData: Array,
    pipelineSummaryStagesData: Object,
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
      series: [
        {
          name: "Deals",
          data: Object.values(this.pipelineSummaryStagesDataValue),
        },
      ],
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
        categories: Object.keys(this.pipelineSummaryStagesDataValue),
      },
      legend: {
        show: false,
      },
    };
  }
  columnChartType() {
    return {
      series: [
        {
          name: "Won Deals",
          data: this.buildChartColumnSeries(this.wonDealsDataValue),
        },
        {
          name: "Lost Deals",
          data: this.buildChartColumnSeries(this.lostDealsDataValue),
        },
      ],
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
        categories: this.buildChartColumnCategories(this.wonDealsDataValue),
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
  buildChartColumnCategories(data) {
    return data.map((item) => {
      const date = new Date(item.timestamp * 1000);
      return date.toLocaleDateString("sv-SE");
    });
  }
  buildChartColumnSeries(data) {
    return data.map((item) => item.value);
  }
}
