 $("#recommendation").click(function(){
      $('#recommended_receivers').slideUp()
      $("#recommendation_loader").slideDown()
      var totalf = [];
      var totalU = [];
      var did = $("#donation_id").text()
      $(".item_description").each(function(){
         totalf.push(this.innerHTML);
      });


      $(".distribution_items").each(function(){
         totalU.push(this.value);
      });

      var items=[]
      var units=[]
      for(var j=0;j<totalf.length;j++){
        if(totalU[j]!=0){
          items.push(totalf[j])
          units.push(totalU[j])
        }
      }

      console.log("here is the item types")
      console.log(items)
      console.log(units)

      if (items!==[]) {
        $.ajax({
            method: "GET",
            url: "/giver/"+did+"/recommendations",
            dataType:'html',
            data: {id:did,item:items,unit:units},
            success: function(response) {

              $("#recommendation_loader").slideUp()
              $('#recommended_receivers').html(response);
              $(".viewdetail").each(function(index){
                if(index == 0){
                  $(this).css("background-color","#dbdde0")
                }

              })
              $('#recommended_receivers').slideDown();

              $(".graph").each(function(){
                 $(this).width($(this).parent().width())
              });



              console.log($('.graph').width())
              showRec()
              showChart()

              return true

            }
        });
      }



    });

    /*https://stackoverflow.com/questions/13627308/add-st-nd-rd-and-th-ordinal-suffix-to-a-number*/
function nth(n){return["st","nd","rd"][((n+90)%100-10)%10-1]||"th"}
    /*https://stackoverflow.com/questions/20966817/how-to-add-text-inside-the-doughnut-chart-using-chart-js*/
    Chart.pluginService.register({
    beforeDraw: function (chart) {
      if (chart.config.options.elements.center) {
        //Get ctx from string
        var ctx = chart.chart.ctx;

        //Get options from the center object in options
        var centerConfig = chart.config.options.elements.center;
        var fontStyle = centerConfig.fontStyle || 'Arial';
        var score = centerConfig.score;
        var fullscore = centerConfig.fullscore;
        var color = centerConfig.color || '#000';
        var sidePadding = centerConfig.sidePadding || 20;
        var sidePaddingCalculated = (sidePadding/100) * (chart.innerRadius * 2)
        //Start with a base font of 30px
        ctx.font = "18px " + fontStyle;

        //Get the width of the string and also the width of the element minus 10 to give it 5px side padding
        var stringWidth = ctx.measureText(score).width;
        var elementWidth = (chart.innerRadius * 2) - sidePaddingCalculated;

        // Find out how much the font can grow in width.
        var widthRatio = elementWidth / stringWidth;
        var newFontSize = Math.floor(30 * widthRatio);
        var elementHeight = (chart.innerRadius * 2);

        // Pick a new font size so it will not be larger than the height of label.
        var fontSizeToUse = 18;

        //Set font settings to draw it correctly.
        ctx.textAlign = 'center';
        ctx.textBaseline = 'middle';
        var centerX = ((chart.chartArea.left + chart.chartArea.right) / 2);
        var centerY = ((chart.chartArea.top + chart.chartArea.bottom) / 2)-fontSizeToUse/2;

        ctx.font = fontSizeToUse+"px " + fontStyle;


        var centerYF =centerY+fontSizeToUse;

        ctx.fillStyle = color;

        //Draw text in center
        ctx.fillText(score, centerX, centerY);

        ctx.fillStyle = '#b8bbc1';

        ctx.fillText(fullscore,centerX,centerYF)

      }
    }
  });




  function showChart() {
    var score_t = $('#score_range').data('score')
    var fscore_t = $('#score_range').data('fscore')

    var voter = $('#voter_preference').data('rank')
    var giver_rank = voter["D"]
    var receiver_rank = voter["R"]
    var operator_rank = voter["F"]
    var deliverer_rank = voter["V"]


    var full_score = parseFloat(fscore_t);
    var score = parseFloat(score_t)


    var txt = score_t + "/" +fscore_t
    var config = {
      type: 'doughnut',
      data: {
        labels: [
        ],
        datasets: [{
          data: [score,full_score-score],
          backgroundColor: [
            "#3399ff",
            "#f0f5f5"
          ]

        }]
      },
    options: {
      cutoutPercentage: 75,
      title: {
           display: false,
           text: ['Preference'],
           padding:2,
           fontSize:12},
      elements: {
        center: {
          score: score_t,
          fullscore:"/"+fscore_t,
          color: '#000000', // Default is #000000
          fontStyle: 'Arial', // Default is Arial
          sidePadding: 20 // Defualt is 20 (as a percentage)
        }
      }
    }
    };

    var ctx = document.getElementById("myChart").getContext("2d");
    var myChart = new Chart(ctx, config);


    var color = Chart.helpers.color;
    var scatterChartData = {
    datasets: [{
       label: 'operator',
       borderColor: "#ffffff",
       backgroundColor: "#ffad33",
       pointRadius: 7,
       /*orange*/
       data: [{
              x: operator_rank,
              y: 0,
              }]
        }, {
       label: 'Group 1',
       borderColor: "#ffffff",
       backgroundColor: "#e60000",
       pointRadius: 7,
       /*red*/
       data: [{
              x: receiver_rank,
              y: 0,
              }]
        }, {
       label: 'Group 2',
       borderColor: "#ffffff",
       backgroundColor: "#0073e6",
       pointRadius: 7,
       /*blue*/
       data: [{
              x: giver_rank,
              y: 0,
              }]
        }, {
       label: 'Group 3',
       borderColor: "#ffffff",
       backgroundColor: "#00b300",
       pointRadius: 7,
       /*green*/
       data: [{
              x: deliverer_rank,
              y: 0,
              }]
        }]
    };
    var ct = document.getElementById('chart').getContext('2d');
    window.myScatter = Chart.Scatter(ct, {
        data: scatterChartData,
        options: {
           tooltips: { enabled: false},
           legend: { display: false},
           showAnno: true,
           maintainAspectRatio: false,
           title: {
           display: false,
           text: 'Voter Preferrences'},
           scales:{
             xAxes:[{
             gridLines:{display:false},
             ticks:{
                min: 1,
                max: full_score,
             }
             }],
             yAxes:[{
             gridLines:{display:false,drawBorder:false},
             ticks:{
                min: 0,
                max: 1,
                stepSize:1,
                display:false,
             }

             }]
           }
        },



    });


   }








function showRec() {
    var directionsService = new google.maps.DirectionsService;
    var directionsDisplay = new google.maps.DirectionsRenderer({suppressMarkers: true,preserveViewport:true});
    var uluru = {lat: #{@giver_location.address.latitude}, lng: #{@giver_location.address.longitude}};
    var map = new google.maps.Map(document.getElementById('map'), {
      zoom: 18,
      center: uluru
    });
    var centerP = uluru

    var marker = new google.maps.Marker({
      position: uluru,
      map: map,
      draggable: true
    });

    var icon = {
        url: 'http://maps.google.com/mapfiles/ms/icons/yellow.png',
        scaledSize: new google.maps.Size(40, 40),
        labelOrigin: new google.maps.Point(20, 15)
    };

    var icon_picked = {
        url: 'http://maps.google.com/mapfiles/ms/icons/green.png',
        scaledSize: new google.maps.Size(40, 40),
        labelOrigin: new google.maps.Point(20, 15)

    }

    var bounds = new google.maps.LatLngBounds();
    var infowindow = new google.maps.InfoWindow();
    var markers = [];
    bounds.extend(uluru)

    var receiver_details = $('#receiver_map').data('receivers');
    var detail_index = parseInt($('#receiver_map').data('detail'));
    var length = receiver_details.length


    for (i = 0; i < length; i++) {
        var label_t = (i+1).toString()
        var rec = receiver_details[i]
        var position = {lat: parseFloat(rec.lat),lng:parseFloat(rec.lng)};


        var infoContent = "<b>"+label_t +". "+ rec.rname +" ("+rec.lname+")"+"</b>"


        if (i+1!=detail_index){
          var marker = new google.maps.Marker({
          position: position,
          map: map,
          label: {text: label_t},
          icon: icon,
          info: infoContent
          });

        }
        bounds.extend(position);


        google.maps.event.addListener(marker, 'click', (function(marker, i) {
                return function() {
                    infowindow.setContent(marker.info);
                    infowindow.open(map, marker);
                }
         })(marker, i));




    }

    i=detail_index-1


    var label_t = (i+1).toString()
    var rec = receiver_details[i]
    var position = {lat: parseFloat(rec.lat),lng:parseFloat(rec.lng)};


    var infoContent = "<b>"+label_t +". "+ rec.rname +" ("+rec.lname+")"+"</b>"



    var marker = new google.maps.Marker({
    position: position,
    map: map,
    label: {text: label_t},
    icon: icon_picked,
    info: infoContent
    });

    centerP=position


    bounds.extend(position);


    google.maps.event.addListener(marker, 'click', (function(marker, i) {
            return function() {
                infowindow.setContent(marker.info);
                infowindow.open(map, marker);
            }
    })(marker, i));


    directionsDisplay.setMap(map);
    directionsService.route({
      origin: uluru,
      destination: position,
      travelMode: 'DRIVING',
    }, function(response, status) {
      if (status === 'OK') {
        directionsDisplay.setDirections(response);
      } else {
        window.alert('Directions request failed due to ' + status);
      }
    });





    map.fitBounds(bounds);
    map.setCenter(position);
}
