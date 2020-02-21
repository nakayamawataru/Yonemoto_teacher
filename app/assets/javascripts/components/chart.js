$(document).ready(function() {
  $('.chart-select').change(function() {
    if ($(this).attr('name') == 'month') {
      $("select[name='day_number']").val('');
    } else if ($(this).attr('name') != 'within_rank') {
      $("select[name='month']").val('');
    }
    $('#filter-for-chart').submit();
  })

  $('.chart-category').change(function () {
    $('#filter-for-chart').submit();
  })

  if (gon.chart_category) {
    drawChart(gon.data_rank_category, 'myChartCategory', 600);
  } else {
    drawChart(gon.datasets, 'myChart');
    drawChart(gon.data_rank_abs, 'myChartAbs');
    // Chart benchmark business
    var datasets_benchmark_business = gon.datasets_benchmark_business;
    $.each(datasets_benchmark_business, function (index, value) {
      drawChart(value, 'benchmarkBusiness' + index.toString())
    });
  }

  const urlParams = new URLSearchParams(window.location.search);
  const dateRanking = urlParams.get('date_ranking');
  let date = new Date();
  if (dateRanking !== null) {
    const dateArr = dateRanking.split('/');
    const yearRanking = parseInt(dateArr[2]);
    const monthRanking = parseInt(dateArr[1]) - 1;
    const dayRanking = parseInt(dateArr[0]);
    date = new Date(yearRanking, monthRanking, dayRanking);
  }

  $('#datepicker').datetimepicker({
    viewMode: 'days',
    format: 'DD/MM/YYYY',
    maxDate: new Date(),
    locale: 'ja',
    date: date
  });

  $('.date-fillter').val(gon.default_date)

  $("#datepicker").on("dp.change", function () {
    render_table(false, false);
  })

  $('.next-date').on('click', function () {
    render_table(true, false);
  });

  $('.previous-date').on('click', function () {
    render_table(false, true);
  });


  function render_table(next, previous) {
    const business_id = urlParams.get('business_id') || $('.business-id').val();
    const date = $('.date-fillter').val();

    $.ajax({
      type: 'GET',
      url: '/api/charts/rank_by_date',
      dataType: 'json',
      data: {
        date: date,
        business_id: business_id,
        next: next,
        previous: previous
      },
      success: function (response) {
        $('.text-date').text(response.text_date);
        $('.rank-abs').text(response.rank_abs);
        $('.date-fillter').val(response.date_check);
        $('.data_chart-list').empty();
        $('.data_chart-list').append(text_table(response.data, response.memos));
      }
    });

    $.ajax({
      type: 'GET',
      url: `/businesses/${business_id}/edit_memo`,
      dataType: 'html',
      data: {
        date: date,
        next: next,
        previous: previous,
      },
      success: function (modal) {
        $('#Modal-memos').html(modal)
      }
    });
  };

  function text_table(data, memos) {
    let text = ''
    let textMemos = ''
    let memo = ''
    $.each(data, function (index, value) {
      text +=
        '<tr>' +
        '<td>' + value.date + '</td>' +
        '<td>' + value.ranking + '</td>' +
        '<td>' + text_compare(value.compare_rank) + '</td>' +
        '<td>' + value.keyword + '</td>' +
        '<td>' + value.base_location_japanese + '</td>' +
        '</tr>'
    });
    $.each(memos, function (index, value) {
      memo +=
        `<p>- ${value}</p>`
    });
    textMemos =
      '<tr>' +
      '<th scope="row" class="text-memo-th">メモ</th>' +
      '<td colspan="4" style="text-align: left">' +
      memo +
      '</td>'
      '</tr>'

    return text + textMemos;
  };

  function text_compare(compare_rank) {
    let text = '';
    const absRank = Math.abs(compare_rank).toString();

    if (compare_rank < 0) {
      text = '<span style="color: green;" class="glyphicon glyphicon-arrow-up"></span> ' + absRank;
    } else if (compare_rank > 0) {
      text = '<span style="color: red;" class="glyphicon glyphicon-arrow-down"></span> ' + absRank;
    } else {
      text = '<span style="color: #555;" class="glyphicon glyphicon-arrow-right"></span>';
    }

    return text;
  };

  function drawChart(datasets, elemnet, height=400) {
    var ctx = document.getElementById(elemnet);
    if (!ctx) {
      return;
    }

    ctx.height = height;
    var options = {
      maintainAspectRatio: false,
      spanGaps: false,
      legend: {
        position: 'bottom',
      },
      elements: {
        line: {
          tension: 0,
          fill: false
        }
      },
      layout: {
        padding: {
          top: 25,
        }
      },
      plugins: {
        datalabels: {
          display: false,
          align: 'end',
          anchor: 'end',
          color: "black",
          font: {
            family: 'FontAwesome',
            size: 11
          },
          formatter: function(value, context) {
            return context.dataset.icons[0];
          }
        },
        filler: {
          propagate: false
        }
      },
      scales: {
        yAxes: [{
          ticks: {
            max: gon.within_rank,
            min: 0,
            reverse: true,
            stepSize: 1,
            callback: function (v) {
              if (v > 20) {
                return '圏外';
              } else if (v == 0) {
                return '';
              } else {
                if ((v % 5) == 0 || v == 1) {
                  return v + '位';
                } else {
                  return '';
                }
              }
            }
          },
          gridLines: {
            display: true,
          },
          scaleLabel: {
            display: true,
            labelString: '（順位）'
          }
        }],
        xAxes: [{
          stacked: false,
          ticks: {
            maxTicksLimit: 7,
            maxRotation: 0,
            minRotation: 0
          },
          gridLines: {
            display: false
          },
          scaleLabel: {
            display: true,
            labelString: '（日付）'
          }
        }]
      },
      tooltips: {
        mode: 'index',
        intersect: false,
        callbacks: {
          label: function (tooltipItems, data) {
            if (tooltipItems['yLabel'] > 0 && tooltipItems['yLabel'] < 21) {
              return '『' + data['datasets'][tooltipItems['datasetIndex']]['label'] + '』' + tooltipItems['yLabel'] + '位';
            } else if (tooltipItems['yLabel'] === 0 &&  data['datasets'][tooltipItems['datasetIndex']]['label'] === 'メモ') {
              return data['datasets'][tooltipItems['datasetIndex']]['title_memo'][tooltipItems['index']]
            } else {
              return '『' + data['datasets'][tooltipItems['datasetIndex']]['label'] + '』' + '圏外';
            }
          },
          title: function (tooltipItems, data) {
            var label = tooltipItems[0]['xLabel'];
            return label;
          }
        }
      }
    };

    new Chart(ctx, {
      type: 'line',
      data: {
        labels: gon.labels,
        datasets: datasets
      },
      options: Chart.helpers.merge(options, {})
    });
  }

  $('.js-detail-memos').click(function(){
    $('#memosModal').modal('show')
  })
});
