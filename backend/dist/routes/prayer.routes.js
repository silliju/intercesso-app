"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const prayerController = __importStar(require("../controllers/prayer.controller"));
const auth_1 = require("../middleware/auth");
const router = (0, express_1.Router)();
router.get('/', auth_1.optionalAuth, prayerController.getPrayers);
router.get('/:prayerId', auth_1.optionalAuth, prayerController.getPrayerById);
router.post('/', auth_1.authenticate, prayerController.createPrayer);
router.put('/:prayerId', auth_1.authenticate, prayerController.updatePrayer);
router.delete('/:prayerId', auth_1.authenticate, prayerController.deletePrayer);
// 기도 참여
router.post('/:prayerId/participate', auth_1.authenticate, prayerController.participatePrayer);
router.delete('/:prayerId/participate', auth_1.authenticate, prayerController.cancelParticipation);
// 댓글
router.post('/:prayerId/comments', auth_1.authenticate, prayerController.createComment);
router.delete('/comments/:commentId', auth_1.authenticate, prayerController.deleteComment);
// 작정기도
router.get('/:prayerId/checkins', auth_1.authenticate, prayerController.getCovenantCheckins);
router.post('/:prayerId/checkins', auth_1.authenticate, prayerController.checkInCovenant);
exports.default = router;
//# sourceMappingURL=prayer.routes.js.map