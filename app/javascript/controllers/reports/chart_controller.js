import { Controller } from "stimulus";
import ApexCharts from "apexcharts";

export default class extends Controller {
  static values = {
    chartData: Object,
  };

  connect() {
    console.log("Olá mundo: ", this.chartDataValue);
    var options =
      this.chartType === "funnel"
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
          name: this.chartDataValue.data?.[0]?.name,
          data: Object.values(this.chartDataValue.data?.[0]?.series_data),
        },
      ],
      chart: {
        type: "bar",
        height: 350,
        dropShadow: {
          enabled: true,
        },
      },
      colors: this.chartColors,
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
        categories: Object.keys(this.chartDataValue.data?.[0]?.series_data),
      },
      legend: {
        show: false,
      },
    };
  }

  columnChartType() {
    return {
      series: this.buildChartColumnSeriesBody(),
      chart: {
        type: "bar",
        height: 350,
      },
      colors: this.chartColors,
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
        categories: this.timeseriesDates(
          this.chartDataValue?.data?.[0]?.series_data
        ),
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

  get chartType() {
    return this.chartDataValue.chart_type;
  }

  get chartColors() {
    return this.chartDataValue.data.map((item) => item.color);
  }

  buildChartColumnSeriesBody() {
    return this.chartDataValue.data.map((item) => ({
      name: item.name,
      data: this.timeseriesValues(item.series_data),
    }));
  }

  timeseriesDates(data) {
    return data.map((item) => {
      const date = new Date(item.timestamp * 1000);
      return date.toLocaleDateString("sv-SE");
    });
  }
  timeseriesValues(data) {
    return data.map((item) => item.value);
  }
}
