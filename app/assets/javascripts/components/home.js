$(document).ready(function() {

  var ctx = document.getElementById("myChart");
  ctx.height = 220;
  new Chart(ctx, {
    type: "bar",
    data: {
      labels: gon.labels,
      datasets: [{
        label: "メッセージ数",
        data: gon.messages_count,
        backgroundColor: "rgba(60,150,220,0.6)"
      }, {
        label: "レビュー数",
        data: gon.reviews_count,
        backgroundColor: "rgba(250,180,50,0.6)"
      }, {
        label: "目標（メッセージ数）",
        data: gon.goal_messages_count,
        borderColor: "rgba(60,150,220,1)",
        fill: false,
        borderWidth: 1,
        type: "line"
      }, {
        label: "目標（レビュー数）",
        data: gon.goal_reviews_count,
        borderColor: "rgba(250,180,50,0.6)",
        fill: false,
        borderWidth: 1,
        type: "line"
      }]
    },
    options: {
      maintainAspectRatio: true,
      legend: {
        display: true
      },
      elements: {
      line: {
        tension: 0,
        fill: false
      }
    }
    }
  })
})
