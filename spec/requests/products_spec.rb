# encoding: utf-8
require 'spec_helper'
require 'shared_stuff'

describe "Products", js: true do

  include_context 'login admin'

  let(:shop) { user_admin.shop }

  let(:iphone4) { Factory :iphone4, shop: shop, product_type: '智能手机', vendor: '苹果' }

  let(:psp) { Factory :psp, shop: shop, product_type: '游戏机', vendor: '索尼' }

  before :each do
    # 删除默认商品，方便测试
    shop.products.clear
    shop.reload
  end

  ##### 新增 #####
  describe "GET /products/new" do

    # 校验
    describe "validate" do

      context "(without types and vendors)" do

        it "should be validate" do
          visit new_product_path
          #显示新增类型、生产商
          find_field('product[product_type]').visible?.should be_true
          find_field('product[vendor]').visible?.should be_true

          click_on '保存'

          #校验#增加了客户端形式的校验
          within(:xpath,"//label[@for='product_title']") do
            has_content?('不能为空').should be_true
          end
          within(:xpath,"//label[@for='product_vendor']") do
            has_content?('不能为空').should be_true
          end
          within(:xpath,"//label[@for='product_product_type']") do
            has_content?('不能为空').should be_true
          end
        end

      end

      context "(with types)" do

        it "should be validate" do
          #系统已存在类型
          shop.types.create name: '手机'
          visit new_product_path

          #选中已有类型
          find('#product-type-select').value.should eql '手机'
          find_field('product[product_type]').value.should eql '手机'

          #未选中生产商
          find('#product-vendor-select').value.should eql 'create_new'
          find_field('product[vendor]').value.should eql ''

          #隐藏新增类型、显示生产商
          find_field('product[product_type]').visible?.should be_false
          find_field('product[vendor]').visible?.should be_true
        end

      end

      context "(with vendors)" do

        it "should be validate" do
          #系统已存在生产商
          shop.vendors.create name: '苹果'
          visit new_product_path

          #选中已有生产商
          find('#product-vendor-select').value.should eql '苹果'
          find_field('product[vendor]').value.should eql '苹果'

          #未选中生产商
          find('#product-type-select').value.should eql 'create_new'
          find_field('product[product_type]').value.should eql ''

          #显示新增类型、隐藏生产商
          find_field('product[product_type]').visible?.should be_true
          find_field('product[vendor]').visible?.should be_false
        end

      end

    end

    context "(with types and vendors)" do

      before :each do
        #系统已存在类型、生产商
        shop.types.create name: '手机'
        shop.vendors.create name: '苹果'
      end

      # 不要求收货地址，则重量置灰
      it "should be bind require_shipping and weight" do
        visit new_product_path
        find_field('product[variants_attributes][][requires_shipping]').checked?.should be_true
        uncheck('product[variants_attributes][][requires_shipping]')
        find_field('product[variants_attributes][][weight]')[:disabled].should eql 'true'

        check('product[variants_attributes][][requires_shipping]')
        find_field('product[variants_attributes][][weight]')[:disabled].should eql 'false'
      end

      # 选项操作
      describe "options" do

        it "should be add" do
          visit new_product_path
          find('#add-option-bt').visible?.should be_false #多选项区域默认不显示
          check '此商品有 多个 不同的款式.'
          # 显示一个默认的选项，并显示新增按钮
          within(:xpath, "//tr[contains(@class, 'edit-option')][1]") do
            find('.option-selector').value.should eql '标题'
            find_field('product[options_attributes][][name]').value.should eql '标题'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认标题'
            has_no_css?('.del-option').should be_true # 第一个选项没有删除按钮
          end
          click_on '新增另一个选项'
          within(:xpath, "//tr[contains(@class, 'edit-option')][2]") do
            find('.option-selector').value.should eql '大小'
            find_field('product[options_attributes][][name]').value.should eql '大小'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认大小'
            find('.del-option').visible?.should be_true # 删除按钮可见
            # 不能选择标题
            find("option[value='标题']")[:disabled].should eql 'true'
            find("option[value='大小']")[:disabled].should eql 'false'
          end
          click_on '新增另一个选项'
          within(:xpath, "//tr[contains(@class, 'edit-option')][3]") do
            find('.option-selector').value.should eql '颜色'
            find_field('product[options_attributes][][name]').value.should eql '颜色'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认颜色'
            find('.del-option').visible?.should be_true # 删除按钮可见
            # 不能选择标题、大小
            find("option[value='标题']")[:disabled].should eql 'true'
            find("option[value='大小']")[:disabled].should eql 'true'
            find("option[value='颜色']")[:disabled].should eql 'false'
            # 换下名称
            select '材料'
            find_field('product[options_attributes][][name]').value.should eql '材料'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认材料'
            # 自定义
            select '自定义...'
            find_field('product[options_attributes][][name]').value.should eql ''
            fill_in 'product[options_attributes][][name]', with: '容量'
            fill_in 'product[options_attributes][][value]', with: '16G'
          end
          find_link('新增另一个选项').visible?.should be_false #超过三个选项就隐藏按钮
          #click_on '保存'

          # 正常回显
          find_field('此商品有 多个 不同的款式.').checked?.should be_true
          find_link('新增另一个选项').visible?.should be_false #超过三个选项就隐藏按钮
          within(:xpath, "//tr[contains(@class, 'edit-option')][1]") do
            find('.option-selector').value.should eql '标题'
            find_field('product[options_attributes][][name]').value.should eql '标题'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认标题'
            has_no_css?('.del-option').should be_true # 第一个选项没有删除按钮
            # 不能选择大小
            find("option[value='标题']")[:disabled].should eql 'false'
            find("option[value='大小']")[:disabled].should eql 'true'
          end
          within(:xpath, "//tr[contains(@class, 'edit-option')][2]") do
            find('.option-selector').value.should eql '大小'
            find_field('product[options_attributes][][name]').value.should eql '大小'
            find_field('product[options_attributes][][name]').visible?.should be_false
            find_field('product[options_attributes][][value]').value.should eql '默认大小'
            find('.del-option').visible?.should be_true # 删除按钮可见
            # 不能选择标题
            find("option[value='标题']")[:disabled].should eql 'true'
            find("option[value='大小']")[:disabled].should eql 'false'
          end
          within(:xpath, "//tr[contains(@class, 'edit-option')][3]") do
            find('.option-selector').value.should eql 'create_new'
            find_field('product[options_attributes][][name]').value.should eql '容量'
            find_field('product[options_attributes][][value]').value.should eql '16G'
            find('.del-option').visible?.should be_true # 删除按钮可见
            # 不能选择标题、大小
            find("option[value='标题']")[:disabled].should eql 'true'
            find("option[value='大小']")[:disabled].should eql 'true'
          end

          # 删除
          within(:xpath, "//tr[contains(@class, 'edit-option')][3]") do
            find('.del-option').click
          end
          has_no_xpath?("//tr[contains(@class, 'edit-option')][3]").should be_true # 已删除
          find_link('新增另一个选项').visible?.should be_true #显示

          fill_in 'product[title]', with: 'iphone'
          click_on '保存'
          page.should have_content('新增商品成功!')
          shop.products.all.size.should eql 1

          #款式选项默认值
          within(:xpath, "//tr[contains(@class, 'inventory-row')]") do
            find('.option-1').text.should eql '默认标题'
            find('.option-2').text.should eql '默认大小'
          end
        end

      end

      # 库存操作
      describe "inventory" do

        it "should be ignore" do
          visit new_product_path
          fill_in 'product[title]', with: 'iphone'
          click_on '保存'
          page.should have_content('新增商品成功!')
          shop.products.first.variants.first.inventory_quantity.should be_nil
        end

        it "should be save" do
          visit new_product_path
          find_field('现有库存量?').visible?.should be_false
          select '需要ShopQi跟踪此款式的库存情况'
          find_field('现有库存量?')[:value].should eql '1'
          fill_in '现有库存量?', with: 10
          fill_in 'product[title]', with: 'iphone'
          click_on '保存'
          page.should have_content('新增商品成功!')
          shop.products.first.variants.first.inventory_quantity.should eql 10
        end

      end

      # 标签操作
      describe "tags" do

        it "should be save" do
          visit new_product_path
          fill_in 'product[tags_text]', with: '智能手机，触摸屏, GPS'
          fill_in 'product[title]', with: 'iphone'
          click_on '保存'

          page.should have_content('智能手机')
          page.should have_content('触摸屏')
          page.should have_content('GPS')

          # 最近使用
          visit new_product_path
          page.should have_content('智能手机')
          page.should have_content('触摸屏')
          page.should have_content('GPS')
        end

      end

      # 集合操作
      describe "collections" do

        it "should be save" do
          shop.custom_collections.create title: '热门商品'

          visit new_product_path
          check '热门商品'
          fill_in 'product[title]', with: 'iphone'
          click_on '保存'

          within '#product-edit-collections' do
            has_no_content?('此商品不属于任何集合.').should be_true
            has_content?('热门商品').should be_true
          end
        end

      end

      describe '#photo' do # 带上图片 #416

        it 'should be upload' do
          visit new_product_path
          fill_in 'product[title]', with: 'iphone'
          attach_file 'product[images][]', Rails.root.join('spec', 'factories', 'data', 'products', 'iphone4.jpg')
          click_on '保存'
          page.should have_content('新增商品成功!')
          within '#image_list' do
            page.should have_xpath('./li[1]') # 显示图片
          end
        end

      end

    end

  end

  ##### 列表 #####
  describe "GET /products" do

    context "(with two products)" do

      before :each do
        psp
        iphone4
      end

      # 查询
      it "should be search" do
        visit products_path
        has_content?('iphone4').should be_true
        has_content?('psp').should be_true

        click_on '所有厂商'
        click_on '苹果'
        has_content?('iphone4').should be_true
        has_no_content?('psp').should be_true

        # 苹果手机
        click_on '所有类型'
        click_on '手机'
        has_content?('iphone4').should be_true
        has_no_content?('psp').should be_true

        # 苹果游戏机
        click_on '手机'
        click_on '游戏机'
        has_no_content?('iphone4').should be_true
        has_no_content?('psp').should be_true

        # 索尼游戏机
        click_on '苹果'
        click_on '索尼'
        has_no_content?('iphone4').should be_true
        has_content?('psp').should be_true

        # 索尼手机
        click_on '游戏机'
        click_on '手机'
        has_no_content?('iphone4').should be_true
        has_no_content?('psp').should be_true
      end

      # 显示款式
      it "should show inventory" do
        visit products_path
        within(:xpath, "//table[@id='product-table']/tbody/tr[1]") do
          has_content?('iphone4').should be_true
          has_content?('默认标题').should be_true
          has_content?('∞').should be_true
        end
        within(:xpath, "//table[@id='product-table']/tbody/tr[2]") do
          has_content?('psp').should be_true
          has_content?('默认标题').should be_true
          has_content?('∞').should be_true
        end
      end

      # 快捷操作
      it "should be select" do
        collection = shop.custom_collections.create title: '热门商品'
        visit products_path
        # 发布
        within(:xpath, "//table[@id='product-table']/tbody/tr[1]") do
          check 'products[]'
        end
        select '隐藏'
        page.should have_content('批量更新成功!') # 延时处理
        within(:xpath, "//table[@id='product-table']/tbody/tr[1]") { page.should have_css('.status-hidden', visible: true) }
        select '发布'
        page.should have_content('批量更新成功!') # 延时处理
        within(:xpath, "//table[@id='product-table']/tbody/tr[1]") { page.should have_css('.status-hidden', visible: false) } #隐藏提示消失
        select '热门商品'
        title = ''
        within(:xpath, "//table[@id='product-table']/tbody/tr[1]/td[3]") { title = find('a').text }
        page.should have_content('批量更新成功!') # 延时处理
        page.execute_script("window.confirm = function(msg) { return true; }")
        select '删除'
        within("#product-table") { has_no_content?(title).should be_true }
      end

      # 库存视图
      it "should list inventory" do
        variant = iphone4.variants.first
        variant.update_attributes inventory_management: 'shopqi', inventory_quantity: 20, inventory_policy: 'continue'
        visit inventory_products_path
        has_content?('iphone4').should be_true
      end
    end

  end

  ##### 查看 #####
  describe "GET /products/id" do

    context "(with a product)" do

      before :each do
        iphone4
      end

      describe '#duplicate' do # 复制商品

        before :each do
          visit product_path(iphone4)
          click_on '复制此商品'
        end

        it 'should be success' do
          within '#duplicate-product' do
            click_on '复制商品'
          end
          page.should have_content("复制 #{iphone4.title}")
        end

        it 'should not duplication a new product' do #如果sku超过限制，则不能复制商品 #282
          shop.plan_type.stub!(:skus).and_return(shop.variants.size)
          visit product_path(iphone4) #重新加载一遍页面
          click_on '复制此商品'
          within '#duplicate-product' do
            click_on '复制商品'
          end
          page.should_not have_content("复制 #{iphone4.title}")
          current_path.should eql product_path(iphone4)
        end

        it 'should be cancel' do
          find('#duplicate-product').visible?.should be_true
          within '#duplicate-product' do
            click_on '取消'
          end
          find('#duplicate-product').visible?.should be_false
        end

      end

      describe '#photo' do

        before :each do
          visit product_path(iphone4)
        end

        it 'should be upload' do
          find('#upload-label .show-upload-link').click # 上传按钮
          attach_file 'add-file', Rails.root.join('spec', 'factories', 'data', 'products', 'iphone4.jpg')
          page.should have_content('新增成功!')
          within '#image_list' do
            page.should have_xpath('./li[1]') # 显示图片
          end
        end

        it 'should be destroy' do
          find('#upload-label .show-upload-link').click # 上传按钮
          attach_file 'add-file', Rails.root.join('spec', 'factories', 'data', 'products', 'iphone4.jpg')
          page.execute_script("window.confirm = function(msg) { return true; }")
          page.should have_css('#image_list')
          within '#image_list' do
            find('.image-delete').click
          end
          page.should have_content('删除成功!')
          page.should have_no_css('#image_list')
        end

        it 'should be valid' do # 校验文件类型 issues#321
          find('#upload-label .show-upload-link').click # 上传按钮
          attach_file 'add-file', Rails.root.join('spec', 'factories', 'data', 'themes', 'invalid.file')
          page.should have_content('商品图片 格式不正确')
        end

      end

      describe '#edit' do # 修改

        it 'should save title' do
          visit product_path(iphone4)
          click_on '修改'

          fill_in '标题', with: 'iphone'
          # 类型、生产商
          select '新增类型...', from: 'product-type-select'
          fill_in 'product_type', with: '智能手机'
          select '新增厂商...', from: 'product-vendor-select'
          fill_in 'vendor', with: 'Apple'

          click_on '保存'

          find('#product_title a').text.should eql 'iphone'
          within '#product-options' do
            has_content?('智能手机').should be_true
            has_content?('Apple').should be_true
            has_content?('默认标题').should be_true
          end
        end

        it 'should save options' do
          visit product_path(iphone4)
          click_on '修改'

          click_link '新增另一个选项' # 第二个选项
          within(:xpath, "//tr[contains(@class, 'edit-option')][2]") do
            fill_in 'product[options_attributes][][value]', with: '8G'
          end
          click_on '保存'

          within(:xpath, "//tbody[@id='product-options-list']/tr[1]") do
            find('.option-1 strong').text.should eql '标题'
            find('.option-values-show .small').text.should eql '默认标题'
          end
          within(:xpath, "//tbody[@id='product-options-list']/tr[2]") do
            find('.option-2 strong').text.should eql '大小'
            find('.option-values-show .small').text.should eql '8G'
          end

          click_on '修改'
          click_link '新增另一个选项' # 第三个选项
          within(:xpath, "//tr[contains(@class, 'edit-option')][3]") do
            fill_in 'product[options_attributes][][value]', with: '黑色'
          end
          click_on '保存'

          within(:xpath, "//tbody[@id='product-options-list']/tr[3]") do
            find('.option-3 strong').text.should eql '颜色'
            find('.option-values-show .small').text.should eql '黑色'
          end

          # 款式区域
          within '#row-head' do
            find('#option-header-1').text.should eql '标题'
            find('#option-header-2').text.should eql '大小'
            find('#option-header-3').text.should eql '颜色'
          end
          within :xpath, "//tr[contains(@class, 'inventory-row')]" do
            find('.option-1').text.should eql '默认标题'
            find('.option-2').text.should eql '8G'
            find('.option-3').text.should eql '黑色'
          end
          within('#variant-options') do #快捷选择区域
            find('.option-1').text.should eql '默认标题'
            find('.option-2').text.should eql '8G'
            #find('.option-3').text.should eql '黑色'
          end

          # 回显
          visit product_path(iphone4)

          within(:xpath, "//tbody[@id='product-options-list']/tr[1]") do
            find('.option-1 strong').text.should eql '标题'
            find('.option-values-show .small').text.should eql '默认标题'
          end
          within(:xpath, "//tbody[@id='product-options-list']/tr[2]") do
            find('.option-2 strong').text.should eql '大小'
            find('.option-values-show .small').text.should eql '8G'
          end
          within(:xpath, "//tbody[@id='product-options-list']/tr[3]") do
            find('.option-3 strong').text.should eql '颜色'
            find('.option-values-show .small').text.should eql '黑色'
          end

          page.execute_script("window.alert = function(msg) { return true; }")
          page.execute_script("$('.delete-option-link').removeClass('fr')") # 修改删除按钮不可见无法点击的问题
          click_on '修改'
          within(:xpath, "//tr[contains(@class, 'edit-option')][1]") do
            find('.del-option').click #删除
          end
          click_on '保存'
          within(:xpath, "//tbody[@id='product-options-list']/tr[1]") do
            find('.option-1 strong').text.should eql '大小'
            find('.option-values-show .small').text.should eql '8G'
          end
          within(:xpath, "//tbody[@id='product-options-list']/tr[2]") do
            find('.option-2 strong').text.should eql '颜色'
            find('.option-values-show .small').text.should eql '黑色'
          end

          # 款式区域
          within('#row-head') do
            find('#option-header-1').text.should eql '大小'
            find('#option-header-2').text.should eql '颜色'
            has_no_css?('#option-header-3').should be_true
          end
          within :xpath, "//tr[contains(@class, 'inventory-row')]" do
            find('.option-1').text.should eql '8G'
            find('.option-2').text.should eql '黑色'
          end
          within('#variant-options') do #快捷选择
            find('.option-1').text.should eql '8G'
            find('.option-2').text.should eql '黑色'
          end
        end

        describe 'vendor' do # 厂商

          it 'should be update' do # 更新厂商
            shop.vendors.create name: '谷歌'
            visit product_path(iphone4)
            click_on '修改'
            select '谷歌', from: 'product-vendor-select'
            click_on '保存'
            within '#product-options' do # 回显
              page.should have_content('谷歌')
            end
            visit product_path(iphone4) # 刷新页面
            within '#product-options' do
              page.should have_content('谷歌')
            end
            click_on '修改'
            find('#product-vendor-select').value.should eql '谷歌'
          end

          it 'should be add' do # 新增厂商
            visit product_path(iphone4)
            click_on '修改'
            select '新增厂商...', from: 'product-vendor-select'
            fill_in 'vendor', with: 'Apple'
            click_on '保存'
            within '#product-options' do # 回显
              page.should have_content('Apple')
            end
            visit product_path(iphone4)
            within '#product-options' do # 刷新页面
              page.should have_content('Apple')
            end
            click_on '修改'
            find('#product-vendor-select').value.should eql 'Apple'
          end

        end

        describe 'variant' do # 款式

          before(:each) { visit product_path(iphone4) }

          it 'should be validate' do
            shop.plan_type.stub!(:skus).and_return(shop.variants.size)
            visit product_path(iphone4) #重新加载一遍页面
            find('#new-variant-link a').click
            within '#new-variant' do
              fill_in 'product_variant[price]', with: ''
              fill_in 'product_variant[weight]', with: ''
              click_on '保存'
              page.should have_content('基本选项标题 不能为空!') #必填校验
              page.should have_content('价格 不能为空!')
              page.should have_content('重量 不能为空!')
              page.should have_content('商品SKU 超过商店限制!')
              fill_in 'product_variant[option1]', with: '默认标题'
              fill_in 'product_variant[price]', with: '100'
              fill_in 'product_variant[weight]', with: '1'
              click_on '保存'
              has_content?('基本选项 已经存在!').should be_true #唯一性校验
            end
          end

          it 'should be edit' do
            within :xpath, "//ul[@id='variants-list']/li[1]" do
              find('.option-1').text.should eql '默认标题'
              click_link '修改'
              find('.inventory-row').visible?.should be_false
              within '.row-edit-details' do
                fill_in 'product_variant[option1]', with: '最新上市'
              end
              click_on '保存'
            end
            page.should have_content('修改成功!') # 延时处理
            within :xpath, "//ul[@id='variants-list']/li[1]" do
              find('.option-1').text.should eql '最新上市'
            end
            within('#variant-options') do #快捷选择
              find('.option-1').text.should eql '最新上市'
            end
            has_content?('修改成功!').should be_true
          end

          it 'should be add' do
            find('#new-variant-link a').click
            within '#new-variant' do
              fill_in 'product_variant[option1]', with: '最新上市'
              fill_in 'product_variant[price]', with: '100'
              fill_in 'product_variant[weight]', with: '1'
              click_on '保存'
            end

            within :xpath, "//ul[@id='variants-list']/li[2]" do
              find('.inventory-row .option-1').text.should eql '最新上市'
            end
            within('#variant-options') do #快捷选择
              find('.option-1').text.should eql '默认标题 最新上市'
            end
            has_content?('新增成功!').should be_true
          end

          it 'should be add without weight' do # issue#205,新增时不勾选"要求收货地址"
            find('#new-variant-link a').click
            within '#new-variant' do
              fill_in 'product_variant[option1]', with: '最新上市'
              fill_in 'product_variant[price]', with: '100'
              uncheck 'product_variant[requires_shipping]'# 要求收货地址
              click_on '保存'
            end
            page.should have_content('新增成功!')
          end

          it 'should update product options' do
            find('#new-variant-link a').click
            within '#new-variant' do
              fill_in 'product_variant[option1]', with: '最新上市'
              fill_in 'product_variant[price]', with: '100'
              fill_in 'product_variant[weight]', with: '1'
              click_on '保存'
            end
            page.should have_content('新增成功!')

            within(:xpath, "//tbody[@id='product-options-list']/tr[1]") do # 更新显示商品的选项值
              find('.option-values-show .small').text.should eql '默认标题,最新上市'
            end

            has_no_xpath?("//tr[contains(@class, 'edit-option')][2]").should be_true # Bug: 不应该新增重复的选项输入项
          end

          context 'with three options' do # 有三个选项

            before do
              iphone4.options_attributes = [
                {name: '大小', value: '16G'},
                {name: '网络', value: 'WIFI'},
              ]
              iphone4.save
              iphone4.reload # 注意要reload，使option的value重置为空
              visit product_path(iphone4)
            end

            describe 'option' do # 选项

              it 'should move right' do # 向右移动位置
                page.execute_script("$('.mover').show()") # 鼠标悬停时显示
                find('#option-header-1 .mover').click # 箭头图标
                asset_options titles: %w(大小 标题 网络), variants: [%w(16G 默认标题 WIFI)]
                visit product_path(iphone4) # 回显
                asset_options titles: %w(大小 标题 网络), variants: [%w(16G 默认标题 WIFI)]
              end

              it 'should move left' do # 向右移动位置
                page.execute_script("$('.mover').show()") # 鼠标悬停时显示
                find('#option-header-2 .mover:first').click # 箭头图标
                asset_options titles: %w(大小 标题 网络), variants: [%w(16G 默认标题 WIFI)]
                visit product_path(iphone4) # 回显
                asset_options titles: %w(大小 标题 网络), variants: [%w(16G 默认标题 WIFI)]
              end

            end

          end

          describe '(batch)' do # 批量操作

            it 'should change price' do
              check('默认标题')
              within('#product-controls') do
                has_content?('已选中 1 个款式').should be_true
                within('#product-select') do
                  find("option[value='destroy']")[:disabled].should eql 'true' #只剩下一个款式，不能删除
                  find('#dup-option-1')[:disabled].should eql 'false' #只选中一个款式，可以复制
                end
                select '修改价格', from: 'product-select'
                fill_in 'new_value', with: '10'
                click_on '保存'
              end

              has_content?('批量修改成功!').should be_true
              within :xpath, "//ul[@id='variants-list']/li[1]" do
                find('.price-cell').text.should eql '10'
              end
            end

            it 'should be copy' do
              check('默认标题')
              within('#product-controls') do
                select '…使用另一个标题', from: 'product-select'
                fill_in 'new_value', with: '热卖'
                click_on '保存'
              end
              within :xpath, "//ul[@id='variants-list']/li[2]" do
                find('.option-1').text.should eql '热卖'
              end
            end

            it 'should be delete' do
              # 新增款式，两个以上才能执行删除操作
              find('#new-variant-link a').click
              within '#new-variant' do
                fill_in 'product_variant[option1]', with: '最新上市'
                fill_in 'product_variant[price]', with: '100'
                fill_in 'product_variant[weight]', with: '1'
                click_on '保存'
              end
              check('默认标题')
              within('#product-controls') do
                page.execute_script("window.confirm = function(msg) { return true; }")
                select '删除', from: 'product-select'
              end
              page.should have_content('批量删除成功!')
              find('#product-controls').should_not be_visible
              page.should have_no_xpath("//ul[@id='variants-list']/li[2]")
            end

          end

        end

      end

    end

  end

end

DEFAULT_OPTIONS = %w(标题 大小 颜色 材料 风格)

def asset_options(options) # 检查选项
  titles = options[:titles]
  variants = options[:variants]
  titles.each_with_index do |title, index| # 检查选项标题
    find("#option-header-#{index+1}").should have_content(title)
  end
  variants.each_with_index do |variant, index| # 检查款式选项值
    within(:xpath, "//tr[contains(@class, 'inventory-row')][#{index+1}]") do
      variant.each_with_index do |value, index|
        find(".option-#{index+1}").text.should eql value
      end
    end
  end
  values = variants.clone
  values = values.shift.zip *values
  titles.each_with_index do |title, index|  # 检查商品详情显示的选项
    within(:xpath, "//tbody[@id='product-options-list']/tr[#{index+1}]") do
      find(".option-#{index+1} strong").text.should eql title
      find('.option-values-show .small').text.should eql values[index].join(',')
    end
  end
  titles.each_with_index do |title, index| # 检查编辑区域的选项
    within(:xpath, "//tr[contains(@class, 'edit-option')][#{index+1}]") do
      selector = DEFAULT_OPTIONS.include?(title) ? '.option-selector' : '.option-selector-frame input'
      find(selector).value.should eql title
    end
  end
end
