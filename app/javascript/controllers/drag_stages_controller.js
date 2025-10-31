import { Controller } from "stimulus";
import Sortable from "sortablejs";
import Rails from "@rails/ujs";
import * as Turbo from "@hotwired/turbo";

export default class extends Controller {
  static targets = ["lists"];

  connect() {
    this.sort();
  }

  sort() {
    if (this.hasListsTarget) {
      this.sortable = Sortable.create(this.listsTarget, {
        animation: 150,
        handle: '.stage-header',
        draggable: '.stage-column',
        onEnd: this.end.bind(this),
        onStart: () => {
          document.body.classList.add("is-dragging-column");
        },
        forceFallback: true,
      });
    }
  }

  async end(event) {
    document.body.classList.remove("is-dragging-column");
    
    const stageId = event.item.dataset.stageId;
    const newIndex = event.newIndex;
    const pipelineId = this.data.get("id");
    const accountId = window.location.pathname.match(/\/accounts\/(\d+)/)?.[1];

    if (!stageId || !pipelineId || !accountId) {
      return;
    }

    const data = new FormData();
    data.append("stage[position]", newIndex + 1);

    Rails.ajax({
      url: `/accounts/${accountId}/pipelines/${pipelineId}/stages/${stageId}/update_position`,
      type: "PATCH",
      data: data,
      beforeSend: (xhr) => {
        xhr.setRequestHeader("Accept", "text/vnd.turbo-stream.html");
        return true;
      },
      success: (response) => {
        Turbo.renderStreamMessage(response);
      },
      error: () => {
        // Revert on error
        const oldIndex = event.oldIndex;
        const oldElement = event.item;
        const list = this.listsTarget;
        if (oldIndex < newIndex) {
          list.insertBefore(oldElement, list.children[oldIndex + 1]);
        } else {
          list.insertBefore(oldElement, list.children[oldIndex]);
        }
      },
    });
  }
}
