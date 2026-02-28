import { Response } from 'express';
import { ApiResponse, PaginatedResponse } from '../types';

export const sendSuccess = <T>(
  res: Response,
  data: T,
  message = '요청이 성공했습니다',
  statusCode = 200
): Response => {
  const response: ApiResponse<T> = {
    success: true,
    statusCode,
    message,
    data,
  };
  return res.status(statusCode).json(response);
};

export const sendPaginated = <T>(
  res: Response,
  data: T[],
  pagination: { page: number; limit: number; total: number },
  message = '조회 성공'
): Response => {
  const response: PaginatedResponse<T> = {
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

export const sendError = (
  res: Response,
  message: string,
  statusCode = 400,
  errorCode = 'ERROR',
  details?: string
): Response => {
  const response: ApiResponse = {
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
