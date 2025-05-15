class MigrateExistingDealProducts < ActiveRecord::Migration[7.0]
  def up
    DealProduct.find_each do |deal_product|
      deal_product.update!(
        unit_amount_in_cents: deal_product.product.amount_in_cents || 0,
        product_identifier: deal_product.product.identifier || '',
        product_name: deal_product.product.name || '',
        quantity: deal_product.quantity || 1,
        total_amount_in_cents: (deal_product.product&.amount_in_cents || 0) * (deal_product.quantity || 1)
      )
    end

    grouped_deal_products = DealProduct.group(:deal_id, :product_id).select(
      'deal_id',
      'product_id',
      'SUM(quantity) as total_quantity',
      'MIN(id) as min_id',
      'MAX(updated_at) as max_updated_at'
    ).having('COUNT(*) > 1')

    grouped_deal_products.each do |group|
      deal_products = DealProduct.where(deal_id: group.deal_id, product_id: group.product_id)
      first_deal_product = deal_products.first

      consistent = deal_products.all? do |dp|
        dp.unit_amount_in_cents == first_deal_product.unit_amount_in_cents &&
          dp.product_identifier == first_deal_product.product_identifier &&
          dp.product_name == first_deal_product.product_name &&
          dp.account_id == first_deal_product.account_id
      end

      if consistent
        new_deal_product = DealProduct.create!(
          deal_id: group.deal_id,
          product_id: group.product_id,
          account_id: first_deal_product.account_id,
          quantity: group.total_quantity,
          unit_amount_in_cents: first_deal_product.unit_amount_in_cents,
          product_identifier: first_deal_product.product_identifier,
          product_name: first_deal_product.product_name,
          total_amount_in_cents: first_deal_product.unit_amount_in_cents * group.total_quantity,
          created_at: first_deal_product.created_at,
          updated_at: group.max_updated_at
        )

        Rails.logger.info("Consolidado DealProduct: deal_id=#{group.deal_id}, product_id=#{group.product_id}, quantity=#{group.total_quantity}, new_id=#{new_deal_product.id}")

        deal_products.destroy_all
      else
        Rails.logger.warn("Inconsistência nos DealProducts para deal_id: #{group.deal_id}, product_id: #{group.product_id}. Não consolidado.")
      end
    end

    affected_deal_ids = grouped_deal_products.pluck(:deal_id).uniq
    affected_deal_ids.each do |deal_id|
      deal = Deal.find_by(id: deal_id)
      if deal
        Deal::RecalculateAndSaveAllMonetaryValues.new(deal).call
        Rails.logger.info("Recalculado Deal: deal_id=#{deal_id}")
      else
        Rails.logger.warn("Deal não encontrado: deal_id=#{deal_id}")
      end
    end
  end

  def down
    DealProduct.find_each do |deal_product|
      deal_product.update!(
        unit_amount_in_cents: 0,
        product_identifier: '',
        product_name: '',
        total_amount_in_cents: 0
      )
    end

    Rails.logger.warn('A consolidação de DealProducts não é reversível. Registros duplicados foram removidos.')
  end
end
