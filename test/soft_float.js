var SoftFloat = artifacts.require('./SoftFloat.sol');

contract('SoftFloat:f32_add', function(accounts) {
    it("should return a correct value", function(done) {
        var soft_float = SoftFloat.deployed();
        soft_float.then(function(contract){
            return contract.f32_add.call(1075838976, 1066192077);
        }).then(function(result){
            assert.isTrue(result.toString() === '1080452710');
            done();
        })
    });
})

contract('SoftFloat:f32_sub', function(accounts) {
    it("should return a correct value", function(done) {
        var soft_float = SoftFloat.deployed();
        soft_float.then(function(contract){
            return contract.f32_sub.call(1080452710, 1066192077);
        }).then(function(result){
            assert.isTrue(result.toString() === '1075838976');
            done();
        })
    });
})

contract('SoftFloat:f32_div', function(accounts) {
    it("should return a correct value", function(done) {
        var soft_float = SoftFloat.deployed();
        soft_float.then(function(contract){
            return contract.f32_div.call(0x444271ba, 0xc40ae385);
        }).then(function(result){
            assert.isTrue(result.toString() === '3216192307');
            done();
        })
    });
})

contract('SoftFloat:f32_mul', function(accounts) {
    it("should return a correct value", function(done) {
        var soft_float = SoftFloat.deployed();
        soft_float.then(function(contract){
            return contract.f32_mul.call(0x444271ba, 0xc40ae385);
        }).then(function(result){
            console.log(result.toString());
            assert.isTrue(result.toString() === '3369270332');
            done();
        })
    });
})