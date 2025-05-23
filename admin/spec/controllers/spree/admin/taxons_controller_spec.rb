require 'spec_helper'

RSpec.describe Spree::Admin::TaxonsController, type: :controller do
  stub_authorization!

  render_views

  let(:store) { @default_store }
  let(:taxonomy) { create(:taxonomy, store: store) }

  describe 'GET #new' do
    let(:taxon) { create(:taxon, taxonomy: taxonomy) }

    it 'returns a successful response' do
      get :new, params: { taxonomy_id: taxonomy.id, taxon: { parent_id: taxon.id } }
      expect(response).to be_successful
    end

    it 'assigns the parent taxon' do
      get :new, params: { taxonomy_id: taxonomy.id, taxon: { parent_id: taxon.id } }
      expect(assigns(:taxon).parent).to eq(taxon)
    end
  end

  describe 'GET #show' do
    let(:taxon) { create(:taxon, taxonomy: taxonomy) }

    it 'redirects to the edit page' do
      get :show, params: { taxonomy_id: taxonomy.id, id: taxon.id }
      expect(response).to redirect_to(spree.edit_admin_taxonomy_taxon_path(taxonomy.id, taxon.id))
    end
  end

  describe 'GET #edit' do
    let(:taxon) { create(:taxon, taxonomy: taxonomy) }

    it 'returns a successful response' do
      get :edit, params: { taxonomy_id: taxonomy.id, id: taxon.id }
      expect(response).to be_successful
    end
  end

  describe 'PUT #update' do
    let(:taxon) { create(:taxon, taxonomy: taxonomy) }

    it 'returns a successful response' do
      put :update, params: { taxonomy_id: taxonomy.id, id: taxon.id, taxon: { name: 'New Name' } }
      expect(response).to redirect_to(spree.edit_admin_taxonomy_taxon_path(taxonomy.id, taxon.id))
    end

    context 'when permalink_part is present' do
      context 'and no parent taxon' do
        it 'sets the permalink from permalink_part param' do
          put :update, params: { taxonomy_id: taxonomy.id, id: taxonomy.root.id, permalink_part: 'new-permalink' }
          expect(taxonomy.root.reload.permalink).to eq('new-permalink')
        end
      end

      context 'and parent taxon is present' do
        it 'sets the permalink from root permalink and permalink_part param' do
          put :update, params: { taxonomy_id: taxonomy.id, id: taxon.id, permalink_part: 'new-permalink' }
          expect(taxon.reload.permalink).to eq("#{taxonomy.root.permalink}/new-permalink")
        end
      end
    end
  end

  describe 'PUT #reposition' do
    let(:taxon) { create(:taxon, taxonomy: taxonomy) }
    let(:new_parent) { create(:taxon, taxonomy: taxonomy) }

    it 'returns a successful response' do
      put :reposition, params: { taxonomy_id: taxonomy.id, id: taxon.id, taxon: { new_parent_id: new_parent.id, new_position_idx: 0 } }
      expect(response).to be_successful
    end

    it 'repositions the taxon' do
      put :reposition, params: { taxonomy_id: taxonomy.id, id: taxon.id, taxon: { new_parent_id: new_parent.id, new_position_idx: 0 } }
      expect(taxon.reload.parent).to eq(new_parent)
    end
  end

  describe 'DELETE #destroy' do
    let!(:taxon) { create(:taxon, taxonomy: taxonomy) }

    it 'removes the taxon from the database' do
      expect { delete :destroy, params: { taxonomy_id: taxonomy.id, id: taxon.id }, format: :turbo_stream }.to change(Spree::Taxon, :count).by(-1)
    end
  end

  describe 'GET #select_options' do
    before do
      Spree::Taxon.destroy_all
    end

    context 'with automatic taxons param' do
      let!(:automatic_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Automatic Taxon', automatic: true) }
      let!(:manual_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Manual Taxon', automatic: false) }

      it 'returns all taxons' do
        get :select_options, params: { with_automatic: true }
        expect(JSON.parse(response.body)).to contain_exactly(
          { 'id' => automatic_taxon.id, 'name' => automatic_taxon.pretty_name },
          { 'id' => manual_taxon.id, 'name' => manual_taxon.pretty_name }
        )
      end
    end

    context 'without automatic taxons param' do
      let!(:automatic_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Automatic Taxon', automatic: true) }
      let!(:manual_taxon) { create(:taxon, taxonomy: taxonomy, name: 'Manual Taxon', automatic: false) }

      it 'returns only manual taxons' do
        get :select_options
        expect(JSON.parse(response.body)).to eq([{ 'id' => manual_taxon.id, 'name' => manual_taxon.pretty_name }])
      end
    end
  end
end
