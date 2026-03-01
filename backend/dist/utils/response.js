"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.sendError = exports.sendPaginated = exports.sendSuccess = void 0;
const sendSuccess = (res, data, message = '요청이 성공했습니다', statusCode = 200) => {
    const response = {
        success: true,
        statusCode,
        message,
        data,
    };
    return res.status(statusCode).json(response);
};
exports.sendSuccess = sendSuccess;
const sendPaginated = (res, data, pagination, message = '조회 성공') => {
    const response = {
        success: true,
        statusCode: 200,
        message,
        data,
        pagination: {
            ...pagination,
            totalPages: Math.ceil(pagination.total / pagination.limit),
        },
    };
    return res.status(200).json(response);
};
exports.sendPaginated = sendPaginated;
const sendError = (res, message, statusCode = 400, errorCode = 'ERROR', details) => {
    const response = {
        success: false,
        statusCode,
        message,
        error: {
            code: errorCode,
            details,
        },
    };
    return res.status(statusCode).json(response);
};
exports.sendError = sendError;
//# sourceMappingURL=response.js.map