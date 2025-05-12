import { Controller } from "stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static values = {
    chartType: String,
    chartData: Object,
  };
  connect() {
    var options;

    if (this.chartTypeValue === "funnel") {
      options = {
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
    } else {
      options = {
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
          y: {
            formatter: function (val) {
              return "$ " + val + " thousands";
            },
          },
        },
      };
    }

    if (typeof ApexCharts !== "undefined") {
      this.chart = new ApexCharts(this.element, options);
      this.chart.render();
    }
  }
  funnelChartType() {
    return {
      series: [
        {
          name: "Funnel Series",
          data: [1380, 1100, 990, 880, 740, 548, 330, 200],
        },
      ],
      chart: {
        type: "bar",
        height: 350,
        dropShadow: {
          enabled: true,
        },
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
        categories: [
          "Sourced",
          "Screened",
          "Assessed",
          "HR Interview",
          "Technical",
          "Verify",
          "Offered",
          "Hired",
        ],
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
          name: "Net Profit",
          data: [44, 55, 57, 56, 61, 58, 63, 60, 66],
        },
        {
          name: "Revenue",
          data: [76, 85, 101, 98, 87, 105, 91, 114, 94],
        },
        {
          name: "Free Cash Flow",
          data: [35, 41, 36, 26, 45, 48, 52, 53, 41],
        },
      ],
      chart: {
        type: "bar",
        height: 350,
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
        categories: [
          "Feb",
          "Mar",
          "Apr",
          "May",
          "Jun",
          "Jul",
          "Aug",
          "Sep",
          "Oct",
        ],
      },
      fill: {
        opacity: 1,
      },
      tooltip: {
        y: {
          formatter: function (val) {
            return "$ " + val + " thousands";
          },
        },
      },
    };
  }
  disconnect() {
    if (this.chart) {
      this.chart.destroy();
    }
  }
}
