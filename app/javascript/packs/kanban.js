dragula = require("dragula")

stages_count = document.querySelectorAll('.drag-column').length;
elements = []

for (var i = 0; i < stages_count; i++) {
  elements.push(
    document.getElementById(`${i + 1}`)
  )
}

dragula(
  elements
)
	.on("drag", function (el) {
		// add 'is-moving' class to element being dragged
		el.classList.add("is-moving");
	})
	.on("dragend", function (el) {
		var account_id = el.getAttribute('account_id')
		var stage_id = el.parentElement.getAttribute('id')
		var deal_id = el.getAttribute('deal_id')
		update_deal(account_id, deal_id, stage_id)
		// remove 'is-moving' class from element after dragging has stopped
		el.classList.remove("is-moving");

		// add the 'is-moved' class for 600ms then remove it
		window.setTimeout(function () {
			el.classList.add("is-moved");
			window.setTimeout(function () {
				el.classList.remove("is-moved");
			}, 600);
		}, 100);
	});

	function update_deal(account_id, deal_id, stage_id) {
		result = $.ajax({
			url: `/accounts/${account_id}/deals/${deal_id}.json`,
			type: "PUT",
			headers: {
				'Content-Type':'application/json',
				"X-CSRF-TOKEN": document.head.querySelector("[name='csrf-token']").content
			},
			dataType: 'json',
			data: JSON.stringify({"deal":{"stage_id": stage_id}}),
			success: function(data) {},
			error: function(data) {}
		})
	}

var createOptions = (function () {
	var dragOptions = document.querySelectorAll(".drag-options");

	// these strings are used for the checkbox labels
	var options = ["Research", "Strategy", "Inspiration", "Execution"];

	// create the checkbox and labels here, just to keep the html clean. append the <label> to '.drag-options'
	function create() {
		for (var i = 0; i < dragOptions.length; i++) {
			options.forEach(function (item) {
				var checkbox = document.createElement("input");
				var label = document.createElement("label");
				var span = document.createElement("span");
				checkbox.setAttribute("type", "checkbox");
				span.innerHTML = item;
				label.appendChild(span);
				label.insertBefore(checkbox, label.firstChild);
				label.classList.add("drag-options-label");
				dragOptions[i].appendChild(label);
			});
		}
	}

	return {
		create: create
	};
})();

var showOptions = (function () {
	// the 3 dot icon
	var more = document.querySelectorAll(".drag-header-more");

	function show() {
		// show 'drag-options' div when the more icon is clicked
		var target = this.getAttribute("data-target");
		var options = document.getElementById(target);
		options.classList.toggle("active");
	}

	function init() {
		for (var i = 0; i < more.length; i++) {
			more[i].addEventListener("click", show, false);
		}
	}

	return {
		init: init
	};
})();

createOptions.create();
showOptions.init();
