# frozen_string_literal: true

RSpec.describe 'Smoke test' do
  specify 'default call' do
    class MyLittleOperation < SmartCore::Operation
      param :name, :string
      option :meta, :hash
    end

    MyLittleOperation.call('test', meta: {})
  end

  specify 'success result' do
    class MyLittleOperation2 < SmartCore::Operation
      def call
        Success(a: 1, b: 2)
      end
    end

    result = MyLittleOperation2.call

    expect(result).to be_a(SmartCore::Operation::Result::Success)
    expect(result.a).to eq(1)
    expect(result.b).to eq(2)
    expect(result.to_h).to match(a: 1, b: 2)

    expect(result.success?).to eq(true)
    expect(result.failure?).to eq(false)
    expect(result.fatal?).to eq(false)
    expect(result.callback?).to eq(false)
  end

  specify 'failure result' do
    class MyLittleOperation3 < SmartCore::Operation
      def call
        Failure(:no_data, :no_ok, user: 1, name: 2)
      end
    end

    result = MyLittleOperation3.call

    expect(result).to be_a(SmartCore::Operation::Result::Failure)
    expect(result.error_codes).to contain_exactly(:no_data, :no_ok)
    expect(result.error_context).to match(user: 1, name: 2)

    expect(result.success?).to eq(false)
    expect(result.failure?).to eq(true)
    expect(result.fatal?).to eq(false)
    expect(result.callback?).to eq(false)
  end

  specify 'fatal result' do
    class MyLittleOperation4 < SmartCore::Operation
      def call
        Fatal(:start_to_exit, :or_not?, some_data: true, but_true: false)
        1 + 2
      end
    end

    result = begin
      MyLittleOperation4.call
    rescue SmartCore::Operation::Result::Fatal::FatalError => error_object
      error_object
    end

    expect(result).to be_a(SmartCore::Operation::Result::Fatal::FatalError)
    expect(result.result).to be_a(SmartCore::Operation::Result::Fatal)
    expect(result.result.error_codes).to contain_exactly(:start_to_exit, :or_not?)
    expect(result.result.error_context).to match(some_data: true, but_true: false)

    expect(result.result.success?).to eq(false)
    expect(result.result.failure?).to eq(false)
    expect(result.result.fatal?).to eq(true)
    expect(result.result.callback?).to eq(false)
  end

  specify 'callback result' do
    class MyLittleOperation5 < SmartCore::Operation
      def call
        Callback do
          'test100500'
        end
      end
    end

    result = MyLittleOperation5.call

    expect(result).to be_a(SmartCore::Operation::Result::Callback)
    expect(result.call).to eq('test100500')
    expect(result.call(Object.new)).to eq('test100500')
    expect(result.callback).to be_a(Proc)
    expect(result.callback.call).to eq('test100500')

    expect(result.success?).to eq(false)
    expect(result.failure?).to eq(false)
    expect(result.fatal?).to eq(false)
    expect(result.callback?).to eq(true)
  end

  specify 'result-block-notation' do
    class MegaOperation < SmartCore::Operation
      param :switcher

      def call
        case switcher
        when 1 then Success()
        when 2 then Failure()
        when 3 then Fatal()
        when 4 then Callback(&(proc {}))
        end
      end
    end

    MegaOperation.call do |result|
      result.success?  {  }
      result.failure?  {  }
      result.fatal?    {  }
      result.callback? {  }
    end
  end
end