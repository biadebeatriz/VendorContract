const PRICE_1ST_BATCH = 80 * 10**15;
const PRICE_2ND_BATCH = 90 * 10**15;
const PRICE_3RD_BATCH = 95 * 10**15;
const PRICE_PUBLIC_SALE = 100 * 10**15;

const MAX_SUPPLY_1ST_BATCH = 2090000 * 10**18;
const MAX_SUPPLY_2ND_BATCH = 4180000 * 10**18;
const MAX_SUPPLY_3RD_BATCH = 6270000 * 10**18;
// const MAX_SUPPLY_PUBLIC_SALE = 8360000 * 10**18;

const isPO = false
const isP2 = false
// const isOpen = false
const totalSold = 0

/**
 * se tamo no 1o lote => totalSold é menor que MAX_SUPPLY_1ST_BATCH,  priceToken é PRICE_1ST_BATCH,  isP2 e isP0 são false
 * se tamo no 2o lote => totalSold é menor que MAX_SUPPLY_1ST_BATCH,  priceToken é PRICE_1ST_BATCH,  isP2 e isP0 são false
 *
 * */
function priceToken() {
    if (isP2 === true) { // por que soh p2 e p0 sao setaveis na mao?
        return PRICE_2ND_BATCH;
    } else if (isPO === true) {
        return PRICE_PUBLIC_SALE;
    } else if (MAX_SUPPLY_1ST_BATCH >= totalSold) {
        return PRICE_1ST_BATCH;
    } else if (
        totalSold <= (MAX_SUPPLY_1ST_BATCH + MAX_SUPPLY_2ND_BATCH) &&
        totalSold > MAX_SUPPLY_1ST_BATCH // melhoria poss[ivel, simples x < a < y
    ) {
        return PRICE_2ND_BATCH;
    } else if (
        totalSold <=
        (MAX_SUPPLY_1ST_BATCH + MAX_SUPPLY_2ND_BATCH + MAX_SUPPLY_3RD_BATCH) &&
        totalSold > (MAX_SUPPLY_1ST_BATCH + MAX_SUPPLY_2ND_BATCH)
    ) {
        return PRICE_3RD_BATCH;
    } else {
        return PRICE_PUBLIC_SALE;
    }
}

console.log(priceToken())