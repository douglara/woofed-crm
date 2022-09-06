import { Controller } from "stimulus"

export default class extends Controller {
  connect() {
    if(jQuery().select2) {
      $(".select2").select2({
        ajax: {
          url: '/accounts/1/contacts/search',
          data: function (params) {
            var query = {
              q: params.term,
            }
      
            return query;
          },
  
        },
        templateSelection: this.formatState
      });
    }
  }

  formatState (state) {
    if (state.id == '0' ) {
      $("#deal_contact_id").val(state.id)
      return state.text
    }

    $("#deal_contact_id").val(state.id)
    return state.text
  };

}
