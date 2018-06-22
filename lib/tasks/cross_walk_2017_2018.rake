namespace :plan do
  task :crosswalk_2017_2018 => :environment do
    cross_walk_hash = {"82569MA0200001" => "82569MA0200001","82569MA0230001" => "82569MA0230001","82569MA0260001" => "82569MA0260001","82569MA0250001" => "82569MA0250001","82569MA0410001" => "82569MA0410001","88806MA0020003" => "88806MA0020003","88806MA0040003" => "88806MA0040003","88806MA0020006" => "88806MA0020006","88806MA0040006" => "88806MA0040006","88806MA0020045" => "88806MA0020045","88806MA0020008" => "88806MA0020008","88806MA0040008" => "88806MA0040008","88806MA0100002" => "88806MA0100002","88806MA0040053" => "88806MA0040008","88806MA0020052" => "88806MA0020052","88806MA0040052" => "88806MA0040052","34484MA0510001" => "34484MA0510001","34484MA0540001" => "34484MA0540001","34484MA0530001" => "34484MA0530001","34484MA0250002" => "34484MA0250002","34484MA1380002" => "34484MA1380002","34484MA0560001" => "34484MA0560001"}
    cross_walk_hash.each do |hios_2017, hios_2018|
      plan_2017 = Plan.where(active_year: 2017, hios_base_id: hios_2017).first
      plan_2018 = Plan.where(active_year: 2018, hios_base_id: hios_2018).first
      plan_2017.renewal_plan_id = plan_2018.id
      plan_2017.save
    end
  end
end