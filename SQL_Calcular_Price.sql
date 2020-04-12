/*
DESCRIÇÃO / DESCRIPTION
@pt-BR
Este script em T-SQL tem como finalidade exibir a simulação de um financiamento utilizando o método de cálculo PRICE, 
com carência e sem carência. 
O resultado será exibido os valores de amortização, parcela, juros e data de vencimento
============================================================================================================================
@en-US
This T-SQL script has the goal simulate a financing using PRICE method, calculating with lack of financing and without it. 
It'll be shown in the result the values of financing such: interest, amortization, date of payment etc.
*/

DECLARE @QuantidadePrestacoes INT;
DECLARE @TaxaJuros            NUMERIC(20, 10);
DECLARE @SaldoDevedor         NUMERIC(20, 10);
DECLARE @Valor                NUMERIC(20, 10) = 300000.00 -- Valor que será financiado / Value that will be financed
DECLARE @SaldoDevedorAnterior NUMERIC(20, 10);
DECLARE @SaldoDevedorCarencia NUMERIC(20, 10);
DECLARE @Juros                NUMERIC(20, 10);
DECLARE @JurosAnterior        NUMERIC(20, 10);
DECLARE @Amortizacao          NUMERIC(20, 10);
DECLARE @AmortizacaoAnterior  NUMERIC(20, 10);
DECLARE @Prestacao            NUMERIC(20, 10);
DECLARE @Carencia             INT;
DECLARE @DataVencimento       DATE;
DECLARE @Contador             INT;
DECLARE @ContadorCarencia     INT;
DECLARE @NrParcela            INT = 0;

CREATE TABLE #TmpPrice 
(
  DataVenc             DATE, 
  QuantidadePrestacao  INT,
  TaxaJuros            NUMERIC(20, 10),
  SaldoDevedor         NUMERIC(20, 10),
  Juros                NUMERIC(20, 10),
  Amortizacao          NUMERIC(20, 10),
  Nr_Parcela           INT,
  Prestacao            NUMERIC(20, 10)
);

SET @QuantidadePrestacoes = 48       -- Quantidade de Prestacoes / Number of Payments
SET @TaxaJuros            = 0.03;    -- Valor da Taxa de Juros / Value of Interest
SET @SaldoDevedor         = @Valor;  -- Saldo Devedor = Valor Financiado / financing value
SET @Carencia             = 10       -- Carência do Financiamento / Lack of Financing
SET @Contador             = 0;       -- Contador das parcelas / Counter of payments
SET @ContadorCarencia     = 0;       -- Contador para carência / Counter to lack of financing period
SELECT @DataVencimento = GETDATE();  -- Data de Vencimento / Date of Payment

IF @Carencia > 0 
BEGIN
	WHILE @ContadorCarencia <= @Carencia
	BEGIN
	  PRINT @ContadorCarencia
	  --Armazenar o valor no período anterior / store de values of previous period. 
	  SELECT @SaldoDevedorAnterior = @SaldoDevedor
	        ,@JurosAnterior        = @Juros
			,@AmortizacaoAnterior  = @Amortizacao

	  --Calculo Juros / Calculate interest value
	  SELECT @Juros = @SaldoDevedorAnterior * @TaxaJuros;
	  SELECT @SaldoDevedor = @SaldoDevedorAnterior + @Juros
	  INSERT INTO #TmpPrice (       DataVenc,   QuantidadePrestacao,  TaxaJuros,  SaldoDevedor,  Juros,  Amortizacao, Nr_Parcela,  Prestacao)
	                 VALUES (@DataVencimento, @QuantidadePrestacoes, @TaxaJuros, @SaldoDevedor, @Juros, @Amortizacao,         0,  @Prestacao);

	SELECT @DataVencimento = DATEADD(MONTH, 1, @DataVencimento); 	
    SELECT @ContadorCarencia = @ContadorCarencia + 1;	     
	IF @ContadorCarencia = @Carencia
	BEGIN
	   SELECT @SaldoDevedorCarencia = @SaldoDevedor
	   
	   BREAK;
	END
	END
END

WHILE @Contador < @QuantidadePrestacoes
  BEGIN
	  --Armazenar o valor no período anterior / store de values of previous period. 	  
	  SELECT @SaldoDevedorAnterior = @SaldoDevedor
	        ,@JurosAnterior        = @Juros
			,@AmortizacaoAnterior  = @Amortizacao
	  SELECT @NrParcela = @NrParcela + 1;
      	   
	  --Calculo Juros / Calculate Interest
	  SELECT @Juros = @SaldoDevedorAnterior * @TaxaJuros;
	  --Calcular Prestação / Calculate the value of installment
	  SELECT @Prestacao = IIF(@SaldoDevedorCarencia > 0, @SaldoDevedorCarencia, @Valor) * ((POWER((1+@TaxaJuros),@QuantidadePrestacoes)) * @TaxaJuros)/((POWER((1+@TaxaJuros),@QuantidadePrestacoes)) - 1)
	  --Calcular a Amortização / calculate the amortization
      SELECT @Amortizacao = @Prestacao - @Juros 
	  --Saldo Devedor / Outstanding balance
      SELECT @SaldoDevedor = @SaldoDevedorAnterior - @Amortizacao

	  INSERT INTO #TmpPrice (       DataVenc,   QuantidadePrestacao,  TaxaJuros,  SaldoDevedor,   Juros,   Amortizacao, Nr_Parcela,  Prestacao)
	                 VALUES (@DataVencimento, @QuantidadePrestacoes, @TaxaJuros, @SaldoDevedor,  @Juros,  @Amortizacao, @NrParcela, @Prestacao);
	  
	  SELECT @DataVencimento = DATEADD(MONTH, 1, @DataVencimento);

	  SELECT @Contador = @Contador + 1;

      IF @QuantidadePrestacoes = @Contador
		 BREAK;
  END


SELECT * FROM #TmpPrice
DROP TABLE #TmpPrice;
