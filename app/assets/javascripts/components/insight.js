$(document).ready(function () {
  var configOne = {
    type: 'doughnut',
    data: {
      datasets: [{
        data: gon.search_method_data_current_month,
        backgroundColor: ["#ff1493", "#00bfff", "#deb887"],
      }],
      labels: ["直接検索", "間接検索", "ブランド名"]
    },
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: '「ユーザの検索方法」内訳',
        fontSize: 20
      },
      animation: {
        animateRotate: true
      }
    }
  };
  var color = Chart.helpers.color;
  var barChartDataOne = {
    labels: gon.month_labels_month,
    datasets: [{
      label: '直接検索（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ff1493").alpha(0.2).rgbString(),
      borderColor: "#ff1493",
      borderWidth: 1,
      data: gon.last_year_data_month.queries_direct
    }, {
      label: '間接検索（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#00bfff").alpha(0.2).rgbString(),
      borderColor: "#00bfff",
      borderWidth: 1,
      data: gon.last_year_data_month.queries_indirect
    }, {
      label: 'ブランド名（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#deb887)").alpha(0.2).rgbString(),
      borderColor: "#deb887)",
      borderWidth: 1,
      data: gon.last_year_data_month.queries_chain
    }, {
      label: '直接検索（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ff1493",
      data: gon.current_year_data_month.queries_direct
    }, {
      label: '間接検索（今年）',
      stack: 'Stack 1',
      backgroundColor: "#00bfff",
      data: gon.current_year_data_month.queries_indirect
    }, {
      label: 'ブランド名（今年）',
      stack: 'Stack 1',
      backgroundColor: "#deb887",
      data: gon.current_year_data_month.queries_chain
    }]
  };
  var barConfigOne = {
    type: 'bar',
    data: barChartDataOne,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「ユーザの検索方法」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };


  var configTwo = {
    type: 'doughnut',
    data: {
      datasets: [{
        data: gon.display_location_data_current_month,
        backgroundColor: ["#4682b4", "#3cb371"],
      }],
      labels: ["検索画面", "地図画面"]
    },
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: '「施設が表示された箇所」内訳',
        fontSize: 20
      },
      animation: {
        animateRotate: true
      }
    }
  };
  var barChartDataTwo = {
    labels: gon.month_labels_month,
    datasets: [{
      label: '検索画面（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#4682b4").alpha(0.2).rgbString(),
      borderColor: "#4682b4",
      borderWidth: 1,
      data: gon.last_year_data_month.view_search
    }, {
      label: '地図画面（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#3cb371").alpha(0.2).rgbString(),
      borderColor: "#3cb371",
      borderWidth: 1,
      data: gon.last_year_data_month.view_maps
    }, {
      label: '検索画面（今年）',
      stack: 'Stack 1',
      backgroundColor: "#4682b4",
      data: gon.current_year_data_month.view_search
    }, {
      label: '地図画面（今年）',
      stack: 'Stack 1',
      backgroundColor: "#3cb371",
      data: gon.current_year_data_month.view_maps
    }]
  };
  var barConfigTwo = {
    type: 'bar',
    data: barChartDataTwo,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「施設が表示された箇所」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };

  var configThree = {
    type: 'doughnut',
    data: {
      datasets: [{
        data: gon.action_data_current_month,
        backgroundColor: ["#20b2aa", "#7fffd4", "#ffff00"],
      }],
      labels: [
        "ウェブサイト", "経路案内", "電話"
      ]
    },
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: '「施設が表示された後の行動」内訳',
        fontSize: 20
      },
      animation: {
        animateRotate: true
      }
    }
  };

  var barChartDataThree = {
    labels: gon.month_labels_month,
    datasets: [{
      label: 'ウェブサイト（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#20b2aa").alpha(0.2).rgbString(),
      borderColor: "#20b2aa",
      borderWidth: 1,
      data: gon.last_year_data_month.action_website
    }, {
      label: '経路案内（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#7fffd4").alpha(0.2).rgbString(),
      borderColor: "#7fffd4",
      borderWidth: 1,
      data: gon.last_year_data_month.action_driving_direction
    }, {
      label: '電話（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ffff00").alpha(0.2).rgbString(),
      borderColor: "#ffff00",
      borderWidth: 1,
      data: gon.last_year_data_month.action_phone
    }, {
      label: 'ウェブサイト（今年）',
      stack: 'Stack 1',
      backgroundColor: "#20b2aa",
      data: gon.current_year_data_month.action_website
    }, {
      label: '経路案内（今年）',
      stack: 'Stack 1',
      backgroundColor: "#7fffd4",
      data: gon.current_year_data_month.action_driving_direction
    }, {
      label: '電話（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ffff00",
      data: gon.current_year_data_month.action_phone
    }]
  };
  var barConfigThree = {
    type: 'bar',
    data: barChartDataThree,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「施設が表示された後の行動」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };

  var configFour = {
    type: 'doughnut',
    data: {
      datasets: [{
        data: gon.photo_views_data_current_month,
        backgroundColor: ["#ff69b4", "#7fffd4"],
      }],
      labels: ["オーナーが投稿", "顧客が投稿"]
    },
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: '「投稿者別の写真閲覧枚数」内訳',
        fontSize: 20
      },
      animation: {
        animateRotate: true
      }
    }
  };

  var barChartDataFour = {
    labels: gon.month_labels_month,
    datasets: [{
      label: 'オーナーが投稿（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ff69b4").alpha(0.2).rgbString(),
      borderColor: "#ff69b4",
      borderWidth: 1,
      data: gon.last_year_data_month.photo_views_merchant
    }, {
      label: '顧客が投稿（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#7fffd4").alpha(0.2).rgbString(),
      borderColor: "#7fffd4",
      borderWidth: 1,
      data: gon.last_year_data_month.photo_views_customer
    }, {
      label: 'オーナーが投稿（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ff69b4",
      data: gon.current_year_data_month.photo_views_merchant
    }, {
      label: '顧客が投稿（今年）',
      stack: 'Stack 1',
      backgroundColor: "#7fffd4",
      data: gon.current_year_data_month.photo_views_customer
    }]
  };
  var barConfigFour = {
    type: 'bar',
    data: barChartDataFour,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「投稿者別の写真閲覧枚数」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };

  // For Year Chart
  var barChartDataOne = {
    labels: gon.month_labels_year,
    datasets: [{
      label: '直接検索（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ff1493").alpha(0.2).rgbString(),
      borderColor: "#ff1493",
      borderWidth: 1,
      data: gon.last_year_data_year.queries_direct
    }, {
      label: '間接検索（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#00bfff").alpha(0.2).rgbString(),
      borderColor: "#00bfff",
      borderWidth: 1,
      data: gon.last_year_data_year.queries_indirect
    }, {
      label: 'ブランド名（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#deb887").alpha(0.2).rgbString(),
      borderColor: "#deb887",
      borderWidth: 1,
      data: gon.last_year_data_year.queries_chain
    }, {
      label: '直接検索（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ff1493",
      data: gon.current_year_data_year.queries_direct
    }, {
      label: '間接検索（今年）',
      stack: 'Stack 1',
      backgroundColor: "#00bfff",
      data: gon.current_year_data_year.queries_indirect
    }, {
      label: 'ブランド名（今年）',
      stack: 'Stack 1',
      backgroundColor: "#deb887",
      data: gon.current_year_data_year.queries_chain
    }]
  };
  var barConfigYearOne = {
    type: 'bar',
    data: barChartDataOne,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「ユーザの検索方法」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };
  var barChartDataTwo = {
    labels: gon.month_labels_year,
    datasets: [{
      label: '検索画面（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#4682b4").alpha(0.2).rgbString(),
      borderColor: "#4682b4",
      borderWidth: 1,
      data: gon.last_year_data_year.view_search
    }, {
      label: '地図画面（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#3cb371").alpha(0.2).rgbString(),
      borderColor: "#3cb371",
      borderWidth: 1,
      data: gon.last_year_data_year.view_maps
    }, {
      label: '検索画面（今年）',
      stack: 'Stack 1',
      backgroundColor: "#4682b4",
      data: gon.current_year_data_year.view_search
    }, {
      label: '地図画面（今年）',
      stack: 'Stack 1',
      backgroundColor: "#3cb371",
      data: gon.current_year_data_year.view_maps
    }]
  };
  var barConfigYearTwo = {
    type: 'bar',
    data: barChartDataTwo,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「施設が表示された箇所」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };
  var barChartDataThree = {
    labels: gon.month_labels_year,
    datasets: [{
      label: 'ウェブサイト（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#20b2aa").alpha(0.2).rgbString(),
      borderColor: "#20b2aa",
      borderWidth: 1,
      data: gon.last_year_data_year.action_website
    }, {
      label: '経路案内（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#7fffd4").alpha(0.2).rgbString(),
      borderColor: "#7fffd4",
      borderWidth: 1,
      data: gon.last_year_data_year.action_driving_direction
    }, {
      label: '電話（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ffff00").alpha(0.2).rgbString(),
      borderColor: "#ffff00",
      borderWidth: 1,
      data: gon.last_year_data_year.action_phone
    }, {
      label: 'ウェブサイト（今年）',
      stack: 'Stack 1',
      backgroundColor: "#20b2aa",
      data: gon.current_year_data_year.action_website
    }, {
      label: '経路案内（今年）',
      stack: 'Stack 1',
      backgroundColor: "#7fffd4",
      data: gon.current_year_data_year.action_driving_direction
    }, {
      label: '電話（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ffff00",
      data: gon.current_year_data_year.action_phone
    }]
  };
  var barConfigYearThree = {
    type: 'bar',
    data: barChartDataThree,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「施設が表示された後の行動」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };
  var barChartDataFour = {
    labels: gon.month_labels_year,
    datasets: [{
      label: 'オーナーが投稿（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#ff69b4").alpha(0.2).rgbString(),
      borderColor: "#ff69b4",
      borderWidth: 1,
      data: gon.last_year_data_year.photo_views_merchant
    }, {
      label: '顧客が投稿（前年）',
      stack: 'Stack 0',
      backgroundColor: color("#7fffd4").alpha(0.2).rgbString(),
      borderColor: "#7fffd4",
      borderWidth: 1,
      data: gon.last_year_data_year.photo_views_customer
    }, {
      label: 'オーナーが投稿（今年）',
      stack: 'Stack 1',
      backgroundColor: "#ff69b4",
      data: gon.current_year_data_year.photo_views_merchant
    }, {
      label: '顧客が投稿（今年）',
      stack: 'Stack 1',
      backgroundColor: "#7fffd4",
      data: gon.current_year_data_year.photo_views_customer
    }]
  };
  var barConfigYearFour = {
    type: 'bar',
    data: barChartDataFour,
    options: {
      responsive: true,
      legend: {
        position: 'bottom',
        labels: {
          fontSize: 14
        }
      },
      title: {
        display: true,
        text: "「投稿者別の写真閲覧枚数」推移と前年比",
        fontSize: 20
      },
      tooltips: {
        mode: 'index',
        intersect: false
      },
      scales: {
        yAxes: [{
          ticks: {
            beginAtZero: true,
            min: 0
          }
        }]
      },
      animation: {
        animateRotate: true
      }
    }
  };
  
  Chart.plugins.register({

    afterDatasetsDraw: function (chart, easing) {
      var ctx = chart.ctx;

      chart.data.datasets.forEach(function (dataset, i) {

        var meta = chart.getDatasetMeta(i);

        if (!meta.hidden) {
          meta.data.forEach(function (element, index) {

            if (meta.type != 'doughnut') {
              return;
            }
            ctx.fillStyle = 'rgb(32, 21, 25)';

            var fontSize = 18;
            var fontStyle = 'normal';
            var fontFamily = 'Helvetica Neue';
            ctx.font = Chart.helpers.fontString(fontSize, fontStyle, fontFamily);

            var dataString = dataset.data[index].toString();

            ctx.textAlign = 'center';
            ctx.textBaseline = 'middle';

            var padding = 0;
            var position = element.tooltipPosition();

            ctx.fillText(dataString, position.x, position.y - (fontSize / 2) - padding);
          });
        }
      });
    }

  });

  window.onload = function () {
    var ctx = document.getElementById("doughnut-chart-one").getContext("2d");
    window.doughnut = new Chart(ctx, configOne);
    var ctx = document.getElementById("doughnut-chart-two").getContext("2d");
    window.doughnut = new Chart(ctx, configTwo);
    var ctx = document.getElementById("doughnut-chart-three").getContext("2d");
    window.doughnut = new Chart(ctx, configThree);
    var ctx = document.getElementById("doughnut-chart-four").getContext("2d");
    window.doughnut = new Chart(ctx, configFour);

    var ctx = document.getElementById("bar-chart-one").getContext("2d");
    window.bar = new Chart(ctx, barConfigOne);
    var ctx = document.getElementById("bar-chart-two").getContext("2d");
    window.bar = new Chart(ctx, barConfigTwo);
    var ctx = document.getElementById("bar-chart-three").getContext("2d");
    window.bar = new Chart(ctx, barConfigThree);
    var ctx = document.getElementById("bar-chart-four").getContext("2d");
    window.bar = new Chart(ctx, barConfigFour);

    var ctx = document.getElementById("bar-chartfour-year").getContext("2d");
    window.bar = new Chart(ctx, barConfigYearFour);
    var ctx = document.getElementById("bar-chartthree-year").getContext("2d");
    window.bar = new Chart(ctx, barConfigYearThree);
    var ctx = document.getElementById("bar-chartone-year").getContext("2d");
    window.bar = new Chart(ctx, barConfigYearOne);
    var ctx = document.getElementById("bar-charttwo-year").getContext("2d");
    window.bar = new Chart(ctx, barConfigYearTwo);
  };
});
